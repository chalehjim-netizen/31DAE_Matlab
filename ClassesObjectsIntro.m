% See also 'IntroClass.m'

% The static methods and constant properties of a class
% can be called without creating an instance (object)
% of the class:
c1 = IntroClass.PropFour;
c2 = IntroClass.FunctionTwo(3, 5);

% But now we want to create such an instance:
myinstance = IntroClass(7,8);

% See that the properties have been initialized:
c3 = myinstance.PropOne;
c4 = myinstance.PropTwo;

% And that the dependent property is working as well:
c5 = myinstance.PropThree;

% And finally we use the normal method of the class:
c6 = myinstance.FunctionOne(11);