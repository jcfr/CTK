class Foo(object):

  BAR_CLASS_MEMBER = 1

  def __init__(self):
    self.bar_instance_member = 1

  def bar_instance_method(self):
    print("Hello from instance method")

  @staticmethod
  def bar_class_method():
    print("Hello from class method")

f = Foo()

from pprint import pprint as pp
pp(dir(f))

class Object(object): pass

d = Object()
setattr(d, 'Bar', Foo)
