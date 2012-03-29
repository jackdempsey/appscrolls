require 'spec_helper'

describe RailsWizard::Template do
  subject{ RailsWizard::Template }
  let(:scroll){ RailsWizard::Scroll.generate('name','# test') }

  describe '#initialize' do
    it 'should work with classes' do
      subject.new([scroll]).scrolls.should == [scroll]
    end
  end

  describe '#scrolls_with_dependencies' do
    def s(*deps)
      mock(:Class, :requires => deps, :superclass => RailsWizard::Scroll)
    end
    
    subject do
      @template = RailsWizard::Template.new([]) 
      @template.stub!(:scrolls).and_return(@scrolls)
      @template.stub!(:scroll_classes).and_return(@scrolls)
      @template
    end
    
    it 'should return the same number scrolls if none have dependencies' do
      @scrolls = [s, s]
      subject.scrolls_with_dependencies.size.should == 2
    end

    it 'should handle simple dependencies' do
      @scrolls = [s(s, s), s(s)]
      subject.scrolls_with_dependencies.size.should == 5
    end

    it 'should handle multi-level dependencies' do
      @scrolls = [s(s(s))]
      subject.scrolls_with_dependencies.size.should == 3
    end

    it 'should uniqify' do
      a = s
      b = s(a)
      c = s(s, a, b)
      @scrolls = [a,b,c]
      subject.scrolls_with_dependencies.size.should == 4
    end
    
  end
end
