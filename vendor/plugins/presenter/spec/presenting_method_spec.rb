require File.join(File.dirname(__FILE__), 'helper')


describe 'presenting', :type=>:controller do
  controller_name :foo
  
  it 'should be available on controller' do
    ApplicationController.instance_method(:presenting).to_s.should =~ /presenting/
  end
  
  it 'should be available on view' do
    ActionView::Base.instance_method(:presenting).to_s.should =~ /presenting/
  end
  
  it 'should be available on presenter' do
    FooPresenter.instance_method(:presenting).to_s.should =~ /presenting/
  end
  
  describe '(class,instance)' do
    it 'should guess presenter type from class' do
      presenting(Foo, 1).should be_kind_of(FooPresenter)
    end
    
    it 'should return presenter for instance' do
      presenting(Foo, 1).item.should == 1
    end
  end

  describe '(class,array)' do
    it 'should guess presenter type from class' do
      presenting(Foo, [1, 2]).should be_kind_of(FooPresenter)
    end
    
    it 'should return presenter for array' do
      presenting(Foo, [1, 2]).array.should == [1, 2]
    end
  end

  describe '(symbol,instance)' do
    it 'should guess presenter type from symbol' do
      presenting(:foo, 1).should be_kind_of(FooPresenter)
    end
    
    it 'should return presenter for instance' do
      presenting(:foo, 1).item.should == 1
    end
  end

  describe '(symbol,array)' do
    it 'should guess presenter type from class' do
      presenting(:foo, [1, 2]).should be_kind_of(FooPresenter)
    end
    
    it 'should return presenter for array' do
      presenting(:foo, [1, 2]).array.should == [1, 2]
    end
  end

  describe '(instance)' do
    before { @instance = Foo.new }

    it 'should guess presenter type from value' do
      presenting(@instance).should be_kind_of(FooPresenter)
    end
    
    it 'should return presenter for instance' do
      presenting(@instance).item.should == @instance
    end
    
    it 'should fail if value is nil' do
      lambda { presenting(nil) }.should raise_error(NameError)
    end
  end

  describe '(array)' do
    before { @array = [Foo.new, Foo.new] }

    it 'should guess presenter type from controller' do
      presenting(@array).should be_kind_of(FooPresenter)
    end
    
    it 'should return presenter for array' do
      presenting(@array).array.should == @array
    end
  end

  describe '(empty array)' do
    before { @empty = [] }

    it 'should guess presenter type from controller' do
      presenting(@empty).should be_kind_of(FooPresenter)
    end
    
    it 'should return presenter for empty array' do
      presenting(@empty).array.should be_empty
    end
  end

  it 'should use context as controller if context is controller' do
    controller.presenting([]).controller.should == controller
  end
  
  it 'should borrow controller from context if context is not controller' do
    presenting([]).controller.should == controller
  end
  
  it 'should fail if passed too many arguments' do
    lambda { presenting(:foo, [], :bar) }.should raise_error(ArgumentError)
  end
  
end