classdef PYNQ_UI < handle
    %PYNQ_UI Class used to control the UI on a PYNQ-Z2 board from Matlab.
    %Requires a valid PYNQ object as input.

    properties (Constant)
        % The sizes (in pixels) of the fonts, starting with fontsize 1
        fontSizes = [16 24 32]
        fontWidths = [8 12 16]
        % The width and height of the display in pixels
        displayWidth = 240;
        displayHeight = 240;
        % The maximum size of the CurrentString buffer before it gets sent
        % to the PYNQ board.
        maxCurrentString = 900;
        % The minimum firmware version of the SCPI code on the PYNQ board
        minFirmwareVersion = 1.3;
        allowedCharExpr = "[^a-zA-Z\d ~!@#$%^&*()_+`=[]{}|\;:""<>?./]";
    end

    properties (SetAccess = private)
        % A low-level PYNQ_SCPI object which does the real communication.
        PYNQ_Obj
        % This string will be modified by the various functions and, once
        % ready, be sent to the PYNQ board.
        CurrentString = "";
        % A check if the PYNQ object firmwareversion is OK
        firmwareVersionOK = false;
        % Becomes true when a warning has been given already
        writeWarningGiven = false;
    end

    properties
        % An array of structs which can be used to describe the standard
        % textboxes in an UI.
        TextBoxes struct = struct
    end


    methods
        %% Creator and destructor methods
        function obj = PYNQ_UI(PYNQ_obj)
            %PYNQ_UI Construct an instance of this class
            % It requires a valid PYNQ_ML object as input.
            arguments
                PYNQ_obj PYNQ_LIB.PYNQ_ML
            end
            obj.firmwareVersionOK = PYNQ_obj.firmwareversion>=obj.minFirmwareVersion;
            if ~obj.firmwareVersionOK
                warning("The UI functionalities require a PYNQ-board firmware version of 1.3 or higher.")                
            end
            obj.writeWarningGiven = false;
            obj.PYNQ_Obj = PYNQ_obj;
        end
        %% Combined commands
        function textBox (obj,x1y1x2y2,text,fontSize,txtColor,borderColor,bgColor,lineThickness,alignment,margin,autosize,donotExecute)
            %textBox Draws a bounding box with text inside on the PYNQ
            %display
            %
            % Arguments are:
            % x1y1x2y2: the coordinates (in pixels) of the bounding box,
            % starting at the top-left pixel. They should be given as a
            % vector: [x1 y1 x2 y2]. Coordinates start counting at 1.
            %
            % text: the text string to be displayed in the text box. If it
            % is too large, the font size will be decreased (if autosize is on)
            % and if this does not work, the text will be trimmed to fit.
            %
            % fontSize: a number describing which font size to use. Only a
            % limited number of sizes is possible, see the fontSizes
            % constant. Fontsize is described as a number between 1 and 3.
            %
            % txtColor, borderColor, bgColor: The colours of the text, box
            % border and box background respectively. Colours should be
            % specified in RGB either as a hexadecimal value (e.g. 0xFF0000 is
            % red) or as a vector of 3 integers where [255 0 0] is red.
            %
            % lineThickness: The thickness of the line around the box. When
            % 0 there will be no line around the box.
            %
            % alignment: The alignment of the text. This is a 2-element
            % vector for the x- and y-alignment. For x: 1 = left, 2 =
            % center and 3 = right. Similarly, for y: 1 = top, 2 = center
            % and 3 = bottom. For example: [1 2] will align the text left
            % center.
            %
            % margin: The margin in pixels between the inside of the
            % bounding box and the text.
            %
            % autosize: when true, the font size will scale down when the
            % text does not fit in the box (in both directions)
            %
            % donotExecute: if true, the command will not be sent to the
            % PYNQ board yet, but only added to obj.CurrentString. Only
            % once another command with donotExecute == false is executed
            % or writeCommandsToPynq is called.
            arguments
                obj PYNQ_LIB.PYNQ_UI
                x1y1x2y2 (4,1) {mustBeInteger}
                text {mustBeTextScalar}
                fontSize {mustBeInteger, mustBeScalarOrEmpty,mustBePositive} = 3
                txtColor {mustBeInteger} = [255 0 0]
                borderColor {mustBeInteger} = [0 0 0]
                bgColor {mustBeInteger} = [255 255 255]
                lineThickness {mustBeInteger, mustBeNonnegative, mustBeScalarOrEmpty} = 1;
                alignment (2,1) {mustBeInteger} = [2 2]
                margin {mustBeInteger, mustBeNonnegative} = 2;
                autosize {mustBeNumericOrLogical, mustBeScalarOrEmpty} = true;
                donotExecute {mustBeNumericOrLogical, mustBeScalarOrEmpty} = false;
            end
            % Sort the x and y coordinates and force them to fit in the
            % screen width and height.
            x1y1x2y2 = obj.order2DandBound(x1y1x2y2);
            % Calculate the width and height of the box
            boxwidth = x1y1x2y2(3)-x1y1x2y2(1);
            boxheight = x1y1x2y2(4)-x1y1x2y2(2);
            % Add half the line thickness to the (practical) margin.
            margin = margin + floor(lineThickness/2);
            % Margin can be a 2-element vector
            if numel(margin)>1
                hormargin = margin(1);
                vertmargin = margin(2);
            else
                hormargin = margin;
                vertmargin = margin;
            end
            % Calculate the maximum left-over width and height for the text
            % in pixels
            maxtextwidth = boxwidth - 2*hormargin;
            maxtextheight = boxheight - 2*vertmargin;
            % Calculate the x-position of the text, depending on the
            % x-alignment parameter.
            switch alignment(1)
                case 1 % Left alignment
                    x = x1y1x2y2(1)+hormargin;
                case 2 % Center alignment
                    x = floor((x1y1x2y2(1)+x1y1x2y2(3))/2);
                case 3 % Right alignment
                    x = x1y1x2y2(3)-hormargin;
            end
            % Calculate the y-position of the text, depending on the
            % y-alignment parameter.
            switch alignment(2)
                case 1 % Top alignment
                    y = x1y1x2y2(2)+vertmargin;
                case 2 % Center alignment
                    y = floor((x1y1x2y2(2)+x1y1x2y2(4))/2);
                case 3 % Bottom alignment
                    y = x1y1x2y2(4)-vertmargin;
            end
            % Get the width of the text (in pixels)
            textwidth = obj.getTextWidth(text,fontSize);
            % If autosize is on and the fontsize is above 1 then see if
            % rescaling is required.
            if autosize && fontSize>1
                % Decrease the font size if it is above 1 and the text is
                % too wide to fit.
                while (textwidth>maxtextwidth) && fontSize>1
                    fontSize = fontSize-1;
                    % recalculate the text width using the new font size
                    textwidth = textwidth*obj.fontSizes(fontSize)/obj.fontSizes(fontSize+1);
                end
                % Decrease the font size if it is too high for the text box
                while (obj.fontSizes(fontSize)>maxtextheight) && fontSize>1
                    fontSize = fontSize-1;
                end
            end
            % After possible resizing, if the text is still too wide to fit
            % the box, then remove the excessive characters at the end of
            % the string.
            if (textwidth>maxtextwidth)
                maxlength = floor(maxtextwidth * strlength(text) / textwidth);
                text = extractBefore(text,maxlength);
            end
            % If the font is still too high for the box, then give out a
            % warning.
            if obj.fontSizes(fontSize)>maxtextheight
                if fontSize==1
                    warning("Box too low to fit text. Increase box height or reduce margins.")
                else
                    warning("Box too low to fit text. Decrease font size, increase box height or reduce margins.")
                end
            end
            % Finally, do the real stuff:
            if strlength(strtrim(text))<1
                % If the text is empty or only contains spaces, then only
                % draw the box and not the text.
                obj.drawBoxWithBorder(x1y1x2y2,borderColor,bgColor,lineThickness,donotExecute);
            else
                % Otherwise, draw both the box and the text.
                obj.drawBoxWithBorder(x1y1x2y2,borderColor,bgColor,lineThickness,true);
                obj.writeText([x y],text,fontSize,txtColor,alignment,donotExecute);
            end
        end
        function textBoxFromStruct(obj,input,text,donotExecute)
            %textBoxFromStruct Draws a bounding box with text inside on the PYNQ
            %display using a pre-defined struct as input.
            %
            % This is another way to use the textBox method from above.
            % This is used to simplify writing a user-interface.
            % Instead of many separate arguments, it only has
            % three arguments:
            %
            % input: a matlab struct containing the fields defined in the
            % makeTextBoxStructs method.
            %
            % text (optional): a text input which can be used to replace the default
            % text in the input struct.
            %
            % donotExecute: if true, the command will not be sent to the
            % PYNQ board yet, but only added to obj.CurrentString. Only
            % once another command with donotExecute == false is executed
            % or writeCommandsToPynq is called.
            arguments
                obj PYNQ_LIB.PYNQ_UI
                input struct
                text {mustBeTextScalar} = "";
                donotExecute {mustBeNumericOrLogical, mustBeScalarOrEmpty} = false;
            end
            % If the text string argument is empty, the default text from the
            % input struct will be used.
            if strlength(text)<1
                text=input.defaultText;
            end
            % Call the standard textBox method:
            obj.textBox(input.x1y1x2y2,text,input.fontSize,input.txtColor,...
                input.borderColor,input.bgColor,input.lineThickness,...
                input.alignment,input.margin,input.autosize,donotExecute);
        end
        function displayTextBoxes(obj,boxrange,texts,forcerefresh)
            %displayTextBoxes Displays the predefined textboxes from the
            %TextBoxes struct property. Optionally with non-default texts
            % 
            % Arguments are:
            % boxrange: the range of predefined textboxes which need to be
            % displayed/updated. If 0, all textboxes will be updated.
            % Otherwise things like 1:2 or [1 3 5] can be used.
            %
            % texts: an array of strings to be used inside the textboxes.
            % It should have the same number of elements as the range (so
            % not necessarily as the total number of defined textboxes)
            %
            % forcerefresh: normally, TextBoxes will only be redrawn if
            % their contents have changed to reduce flicker and CPU usage.
            % However, sometimes they need to be forced to be (re)drawn.
            % Set this argument to true to enforce this.
            arguments
                obj PYNQ_LIB.PYNQ_UI
                boxrange {mustBeInteger, mustBeVector} = 0
                texts string = ""
                forcerefresh {mustBeNumericOrLogical} = true
            end
            % If range 0 is used, the range will be all defined TextBoxes.
            if boxrange==0
                boxrange=1:numel(obj.TextBoxes);
            end
            % Process all TextBoxes from the defined boxrange
            for i=1:numel(boxrange)
                % If a text is missing or empty, add and make it empty
                if numel(texts)<i || strlength(texts(i))==0
                    text="";
                else % Otherwise use the text from the input
                    text=texts(i);
                end
                % If the text is new, or forcerefresh is used, then display
                % the box.
                if forcerefresh || (~strcmp(text,obj.TextBoxes(boxrange(i)).currentText))
                    obj.textBoxFromStruct(obj.TextBoxes(boxrange(i)),text);
                    % Also update the current box contents
                    obj.TextBoxes(boxrange(i)).currentText = text;
                end
            end
        end
        function makeTextBoxStructs(obj,number)
            %makeTextBoxStructs Makes an array of size number of the
            %standard box structure, complete with default contents.
            arguments
                obj PYNQ_LIB.PYNQ_UI
                number {mustBeInteger,mustBePositive,mustBeScalarOrEmpty} = 1;
            end
            newBoxes(1:number) = struct(...
                'x1y1x2y2',[NaN NaN NaN NaN] ...
                ,'defaultText',"text" ...
                ,'currentText',"oldText" ...
                ,'fontSize',3 ...
                ,'txtColor',0xFF0000 ...
                ,'borderColor',0x000000 ...
                ,'bgColor',0xFFFFFF ...
                ,'lineThickness',2 ...
                ,'alignment', [2 2] ...
                ,'margin', 3 ...
                ,'autosize', true ...
                );
            obj.TextBoxes = newBoxes;
        end
        %% Text commands
        function writeText(obj,x1y1,text,fontSize,txtColor,alignment,donotExecute)
            %writeText Writes text on the PYNQ display
            %
            % Arguments are:
            % x1y1: the coordinates (in pixels) where the should be printed
            % (depending on alignment). They should be given as a
            % vector: [x1 y1]. Coordinates start counting at 1.
            %
            % text: the text string to be displayed.
            %
            % fontSize: a number describing which font size to use. Only a
            % limited number of sizes is possible, see the fontSizes
            % constant. Fontsize is described as a number between 1 and 3.
            %
            % txtColor: The colour of the text. Should be
            % specified in RGB either as a hexadecimal value (e.g. 0xFF0000 is
            % red) or as a vector of 3 integers where [255 0 0] is red.
            %
            % alignment: The alignment of the text. This is a 2-element
            % vector for the x- and y-alignment. For x: 1 = left, 2 =
            % center and 3 = right. Similarly, for y: 1 = top, 2 = center
            % and 3 = bottom. For example: [1 2] will align the text left
            % center.
            %
            % donotExecute: if true, the command will not be sent to the
            % PYNQ board yet, but only added to obj.CurrentString. Only
            % once another command with donotExecute == false is executed
            % or writeCommandsToPynq is called.            
            arguments
                obj PYNQ_LIB.PYNQ_UI
                x1y1 (2,1) {mustBeInteger}
                text {mustBeTextScalar}
                fontSize {mustBeInteger, mustBeScalarOrEmpty,mustBePositive} = 2
                txtColor {mustBeInteger} = [0 0 0]
                alignment (2,1) {mustBeInteger} = [1 2]
                donotExecute {mustBeNumericOrLogical, mustBeScalarOrEmpty} = false;
            end
            % Modify the y-position according to the alignment
            % For bottom alignment (3), no modification is required
            if alignment(2)==1 % Top alignment
                x1y1(2)=x1y1(2)+obj.fontSizes(fontSize);
            elseif alignment(2)==2 % Center alignment
                x1y1(2)=x1y1(2)+floor(obj.fontSizes(fontSize)/2);
            end
            % Modify the x-position according to the alignment
            % For left alignment (1), no modification is required
            if alignment(1)>1
                % Get the width of the text
                width = obj.getTextWidth(text,fontSize);
                if alignment(1) == 2 % Center alignment
                    x1y1(1) = x1y1(1) - floor(width/2);
                elseif alignment(1) == 3 % Right alignment
                    x1y1(1) = x1y1(1) - width;
                end
            end
            % The - ' and , characters will crash the scpi app so we will give an
            % warning when that is used and replace it with something safer.
            if count(text,"'")>0 || count(text,",")>0 || count(text,"-")>0
                warning("Please do not use one of these characters in display strings: ,'-")
                text=strrep(text,"'","`");
                text=strrep(text,",",".");
                text=strrep(text,"-","=");
            end
            % As a final check, filter out any other "complex" character.
            textfiltered = regexprep(text,obj.allowedCharExpr,"");
            if ~strcmp(text,textfiltered)
                warning("Some characters have been filtered out of the text string. Please use only a simple subset of ASCII characters.")
            end
            % Make the string to be sent to the PYNQ object.
            obj.addString("-TEXT," + ...
                num2str(x1y1(1)-1) + "," + ... % Coordinates start counting at 1, but at 0 on the PYNQ board.
                num2str(x1y1(2)-1) + "," + ...
                num2str(fontSize-1) + "," + ... % Font size starts to count at 0 on PYNQ
                obj.col2RGB565(txtColor) + "," + ... % Color is converted from hex/24 bit vector to a 16 bit hex value
                textfiltered);
            % If it can be executed, then write the string to the PYNQ
            if ~donotExecute
                obj.writeCommandsToPynq;
            end
        end

        %% Display methods
        function displayShowMessage(obj,message)
            %displayShowMessage Shows a message on the LCD-display.
            %message should be a string array, of which each element
            %will be displayed on a separate line. Note that there is
            %a maximum of six lines and twenty characters (including) spaces
            %per line. Excessive lines or characters will be ignored.
            arguments
                obj PYNQ_LIB.PYNQ_ML
                message {mustBeText} % A string or char variable containing the message to be shown
            end
            obj.PYNQ_Obj.Display_ShowMessage(message);
        end
        function width = getTextWidth(obj,text,size)
            %getTextWidth Gets the width (in pixels) of a specified text string of a certain
            % font size on the PYNQ display.
            arguments
                obj PYNQ_LIB.PYNQ_UI
                text {mustBeTextScalar}
                size {mustBeInteger, mustBeScalarOrEmpty,mustBePositive} = 1
            end
            % % Construct the SCPI command string
            % commandString = strcat(":DISPLAY:LengthMessage? '",text,"'");
            % % Send the command to the SCPI device
            % response = obj.PYNQ_Obj.scpiObj.writeReadCommand(commandString);
            % width = floor((str2double(response)-35)*obj.fontSizes(size)/obj.fontSizes(1));
            width = strlength(text) * obj.fontWidths(size);
        end
        %% Bounding box commands
        function drawSimpleBox(obj,x1y1x2y2,bgColor,filled,donotExecute)
            %drawSimpleBox Draws a rectangle of one color (filled or only
            %a border).
            %
            % Arguments are:
            % x1y1x2y2: the coordinates (in pixels) of the bounding box,
            % starting at the top-left pixel. They should be given as a
            % vector: [x1 y1 x2 y2]. Coordinates start counting at 1.
            %
            % bgColor: The colour of the box. Colours should be
            % specified in RGB either as a hexadecimal value (e.g. 0xFF0000 is
            % red) or as a vector of 3 integers where [255 0 0] is red.
            %
            % filled: when true, the box will be completely filled,
            % otherwise only a 1 pixel wide rectangle will be drawn.
            %
            % donotExecute: if true, the command will not be sent to the
            % PYNQ board yet, but only added to obj.CurrentString. Only
            % once another command with donotExecute == false is executed
            % or writeCommandsToPynq is called.
            arguments
                obj PYNQ_LIB.PYNQ_UI
                x1y1x2y2 (4,1) {mustBeInteger}
                bgColor {mustBeInteger} = [0 0 0]
                filled {mustBeNumericOrLogical, mustBeScalarOrEmpty} = true
                donotExecute {mustBeNumericOrLogical, mustBeScalarOrEmpty} = false;
            end
            % Sort and bound the coordinates to the PYNQ display
            x1y1x2y2 = obj.order2DandBound(x1y1x2y2);

            % Make the string to be sent to the PYNQ board
            obj.addString("-BB," + ...
                num2str(x1y1x2y2(1)-1) + "," + ... % Coordinates start counting at 1, but at 0 on the PYNQ board.
                num2str(x1y1x2y2(2)-1) + "," + ...
                num2str(x1y1x2y2(3)-1) + "," + ...
                num2str(x1y1x2y2(4)-1) + "," + ...
                ifthenelse(filled,"1","0") + "," + ... % Write a 1 if the rectangle needs to be filled and a 0 if not
                obj.col2RGB565(bgColor)); % Color is converted from hex/24 bit vector to a 16 bit hex value
            % If it can be executed, then write the string to the PYNQ
            if ~donotExecute
                obj.writeCommandsToPynq;
            end
        end
        function drawBoxWithBorder(obj,x1y1x2y2,borderColor,bgColor,lineThickness,donotExecute)
            %drawBoxWithBorder Draws a rectangle of one color with a border
            % in another colour and of a specified thickness.
            %
            % Arguments are:
            % x1y1x2y2: the coordinates (in pixels) of the bounding box,
            % starting at the top-left pixel. They should be given as a
            % vector: [x1 y1 x2 y2]. Coordinates start counting at 1.
            %
            % borderColor, bgColor: The colours of the box
            % border and box background respectively. Colours should be
            % specified in RGB either as a hexadecimal value (e.g. 0xFF0000 is
            % red) or as a vector of 3 integers where [255 0 0] is red.
            %
            % lineThickness: The thickness of the line around the box. When
            % 0 there will be no line around the box.
            %
            % donotExecute: if true, the command will not be sent to the
            % PYNQ board yet, but only added to obj.CurrentString. Only
            % once another command with donotExecute == false is executed
            % or writeCommandsToPynq is called.
            arguments
                obj PYNQ_LIB.PYNQ_UI
                x1y1x2y2 (4,1) {mustBeInteger}
                borderColor {mustBeInteger} = [0 0 0]
                bgColor {mustBeInteger} = [255 255 255]
                lineThickness {mustBeInteger, mustBeNonnegative,mustBeScalarOrEmpty} = 1;
                donotExecute {mustBeNumericOrLogical, mustBeScalarOrEmpty} = false;
            end
            % Sort and bound the coordinates to the PYNQ display
            x1y1x2y2 = obj.order2DandBound(x1y1x2y2);
            
            % If lineThickness == 0, then only the inside box needs to be
            % drawn.
            if lineThickness<1
                obj.drawSimpleBox(x1y1x2y2,bgColor,1,donotExecute);
            else
                % Otherwise, two boxes will be drawn, a bigger one with the
                % border colour and a smaller one with the background
                % color.
                offset1 = -floor(lineThickness/2);
                obj.drawSimpleBox([x1y1x2y2(1)+offset1 x1y1x2y2(2)+offset1 x1y1x2y2(3)-offset1 x1y1x2y2(4)-offset1]...
                    ,borderColor,1,true);
                offset2 = lineThickness+offset1;
                obj.drawSimpleBox([x1y1x2y2(1)+offset2 x1y1x2y2(2)+offset2 x1y1x2y2(3)-offset2 x1y1x2y2(4)-offset2], ...
                    bgColor,1,donotExecute);
            end
        end

        %% DISPLAY IMAGE
        function displayImage(obj,imagefileordata)
            %displayImage Displays a (.bmp) image on the PYNQ display.
            %
            % The input (imagefileordata) is either the filename of a
            % .bmp file, or a preloaded imageData struct, made with
            % the loadImage method.
            % A bmp file should be 240x240 pixels or smaller with a 24 bit
            % per pixel bitdepth.
            arguments
                obj PYNQ_LIB.PYNQ_UI
                imagefileordata
            end

            % Check if the input is a struct (pre-loaded data) or a string
            % (a filename)
            if isstruct(imagefileordata)
                imageData = imagefileordata;
            elseif isstring(imagefileordata)
                imageData = obj.loadImage(imagefileordata);
            else
                error("Input should be either existing image data, or a filename of a .bmp file.")
            end

            if imageData.hexData==0
                warning("No image data loaded, no image will be displayed.")
            elseif ~obj.firmwareVersionOK
                if ~obj.writeWarningGiven
                    warning("Writing an image requires PYNQ scpi firmware version 1.3 or higher.")
                    obj.writeWarningGiven = true;
                end
            else
                % Construct the SCPI command string
                commandString = sprintf(':DISPLAY:IMAGE #%d%d', ...
                    length(num2str(imageData.bytes)), imageData.bytes);
                fullCommandString = strcat(commandString, imageData.hexData);
                % Send the command to the SCPI device
                obj.PYNQ_Obj.scpiObj.writeCommand(fullCommandString);
            end
        end
        %% Other commands
        function writeCommandsToPynq(obj)
            %writeCommandsToPynq Writes any existing UI commands in the
            %command buffer (obj.CurrentString) to the PYNQ device.
            arguments
                obj PYNQ_LIB.PYNQ_UI
            end
            if ~obj.firmwareVersionOK
                if ~obj.writeWarningGiven
                    warning("Writing to the UI requires PYNQ scpi firmware version 1.3 or higher.")
                    obj.writeWarningGiven = true;
                end
            else
                % Make the complete SCPI command string
                commandString = ":DISPLAY:UI '" + obj.CurrentString +"'";
                obj.PYNQ_Obj.scpiObj.writeCommand(commandString);
            end
            % Clear the command buffer.
            obj.CurrentString="";
        end
        function clearScreen(obj,full,donotExecute)
            %clearScreen Clears the screen of the PYNQ board and fills it
            %with a white background.
            %
            % Arguments are:
            % full: If true, the entire screen (240x240 pixels) is cleared,
            % otherwise only the top part (240x180 pixels) is cleared.
            %
            % donotExecute: if true, the command will not be sent to the
            % PYNQ board yet, but only added to obj.CurrentString. Only
            % once another command with donotExecute == false is executed
            % or writeCommandsToPynq is called.
            arguments
                obj PYNQ_LIB.PYNQ_UI
                full {mustBeNumericOrLogical, mustBeScalarOrEmpty} = false;
                donotExecute {mustBeNumericOrLogical, mustBeScalarOrEmpty} = false;
            end
            if full
                maxy = 239;
            else
                maxy = 179;
            end
            obj.drawSimpleBox([0 0 239 maxy],0xFFFFFF,1,donotExecute);
        end
    end
    methods (Access=private)
        function addString(obj,newstring)
            %addString Adds a value to the obj.CurrentString property. If
            %obj.CurrentString becomes too large, it is written to the PYNQ
            %board.
            arguments
                obj PYNQ_LIB.PYNQ_UI
                newstring {mustBeTextScalar}
            end            
            
            % If CurrentString was not empty, first add a comma to it.
            if strlength(obj.CurrentString)>0
                obj.CurrentString = obj.CurrentString + ",";
            end
            % Add the new string
            obj.CurrentString = obj.CurrentString + newstring;
            % If CurrentString is too long, write to the PYNQ board.
            if strlength(obj.CurrentString)>obj.maxCurrentString
                obj.writeCommandsToPynq;
            end
        end
        function input = order2DandBound(obj,input)
            %order2DandBound reorders an x1y1x2y2 array such that x1<x2 and
            %y1<y2. Also makes sure that both fall within the bounds of the
            %PYNQ display.
            arguments
                obj PYNQ_LIB.PYNQ_UI
                input (4,1) {mustBeInteger}
            end
            % Re-order x and y values
            [input(1),input(3)] = order(input(1),input(3));
            [input(2),input(4)] = order(input(2),input(4));
            % Bound the values
            input(1)=max(input(1),1);
            input(2)=max(input(2),1);
            input(3)=min(input(3),obj.displayWidth);
            input(4)=min(input(4),obj.displayHeight);
        end
    end
    methods (Static)
        function imageData = loadImage(inputimagefilename,appName)
            %loadImage Loads a (.bmp) image to be later displayed on the LCD screen.
            %
            % The first input (imagefilename) is the filename of a
            % .bmp file. It should be 240x240 pixels or smaller with a 24 bit
            % per pixel bitdepth.
            % 
            % The second input is the optional name of the app using the
            % files, which may be used to determine the folder if the file
            % was not found at the imagefilename location.
            arguments
                inputimagefilename {mustBeTextScalar}
                appName {mustBeTextScalar} =""
            end
            % Check if the file exists, if not, give an error.
            nofile = false;
            if ~isfile(inputimagefilename)
                % If the file was not found in the expected place, maybe it
                % is in a subfolder of the currently running app.

                % if ~isfile(imagefilename)
                    imagefilename = fullfile(fileparts(mfilename('fullpath')),inputimagefilename);
                    if ~isfile(imagefilename)
                        imagefilename = fullfile(fileparts(fileparts(mfilename('fullpath'))),inputimagefilename);
                        if ~isfile(imagefilename)
                            rootSettings = matlab.internal.getSettingsRoot;
                            addonFolder  = rootSettings.matlab.addons.InstallationFolder.ActiveValue;
                            appfolder = fullfile(addonFolder,'Apps',appName);
                            imagefilename = fullfile(appfolder,inputimagefilename);
                            if ~isfile(imagefilename)
                                warning("Input should be an existing .bmp file. " + inputimagefilename + " cannot be found." )
                                nofile = true;
                            end
                        end
                    end
                % end
            else
                imagefilename = inputimagefilename;
            end
            if nofile
                imageData.hexData=0;
                imageData.bytes = 0;
            else
                % Check if the file extension is .bmp, if not, give an error.
                [~, ~, fExt] = fileparts(imagefilename);
                if ~strcmpi(fExt,".bmp")
                    error("Input should be an existing .bmp file."  + imagefilename + " is of another type." )
                end
                % Open the file
                fileID = fopen(imagefilename, 'rb');
                if fileID == -1
                    error('Error opening image file');
                end
                % Read the entire contents of the file
                bmpData = fread(fileID, inf, '*uint8');
                % Close the file
                fclose(fileID);
                % Convert the byte array to a string of hexadecimal values
                imageData.hexData = sprintf('%02X', bmpData);
                imageData.bytes = length(imageData.hexData);
            end
        end
        function rgb565 = col2RGB565(col)
            %col2RGB565 Converts a color in hexadecimal value
            % (e.g. 0xFF0000 is red) or as in a vector of 3 
            % integers (where [255 0 0] is red) to a 16 bit RGB565 value,
            % which is what is needed as input for PYNQ display colors.
            arguments
                col {mustBeNumeric}
            end
            % First see which type if input was given and then extract the
            % r, g and b values.
            if numel(col)>1
                % Ensure the inputs are 8-bit unsigned integers
                r = uint8(col(1));
                g = uint8(col(2));
                b = uint8(col(3));
            else
                % Ensure the input is a 24-bit hexadecimal value
                hexColor = uint32(col);

                % Extract the red, green, and blue components from the 24-bit color
                r = uint8(bitshift(bitand(hexColor, uint32(0xFF0000)), -16));
                g = uint8(bitshift(bitand(hexColor, uint32(0x00FF00)), -8));
                b = uint8(bitand(hexColor, uint32(0x0000FF)));
            end

            % Convert the 8-bit RGB values to the RGB565 format
            % r is 5 bits, g is 6 bits, b is 5 bits
            r5 = bitshift(bitand(r, uint8(0xF8)), -3); % Convert r from 8-bit to 5-bit
            g6 = bitshift(bitand(g, uint8(0xFC)), -2); % Convert g from 8-bit to 6-bit
            b5 = bitshift(bitand(b, uint8(0xF8)), -3); % Convert b from 8-bit to 5-bit

            % Combine the r5, g6, and b5 values into a single 16-bit RGB565 value
            rgb565 = dec2hex(bitor(bitshift(uint16(r5), 11), bitor(bitshift(uint16(g6), 5), uint16(b5))));
        end
    end
end
function [a_out, b_out] = order(a_in, b_in)
% Reorder two values such that a_out<=b_out
if a_in>b_in
    a_out=b_in;
    b_out=a_in;
else
    a_out=a_in;
    b_out=b_in;
end
end
function result = ifthenelse(input,trueval,falseval)
    % A simple function that is missing in Matlab
    if input
        result = trueval;
    else
        result = falseval;
    end
end