[![Build Status](https://travis-ci.org/felixflores/railway_operation.svg?branch=master)](https://travis-ci.org/felixflores/railway_operation)

# RailwayOperation

This gem allows you to declare and compose a set of operations into a functional execution tree inspired by the railway oriented programming pattern. See ([https://fsharpforfunandprofit.com/rop/](https://fsharpforfunandprofit.com/rop/)) for more details.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'railway_operation'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install railway_operation
    
Then in any of your ruby class `include RailwayOperation::Operator`.

## Basic Usage
Let's say we have the following class

```ruby
module Readme
  class Example1_1
    def initialize(someone = 'someone')
      @someone = someone
    end

    def first_method(argument)
      argument << "Hello #{@someone}, from first_method."
    end

    def another_method(argument)
      argument << 'Hello from another_method.'
    end

    def final_method(argument)
      argument << 'Hello from final_method.'
    end
  end
end
```

We could perform the follow chain of execution, to yield the following result.

```ruby
ex1 = Readme::Example1.new('Felix')
argument = []

result = ex1.first_method([])
result = ex1.another_method(result)
result = ex1.final_method(result)

result == [
  'Hello Felix, from first_method.'
  'Hello from another_method.'
  'Hello from final_method.'
]
```

RailwayOperation provides a way for you to declare the same execution chain as a series of steps in an operation. 

If we add the following

```ruby
module Readme
  class Example1
    include RailwayOperation
```

to your class, we can then declare an operation block

```ruby
operation do |o|
  o.add_step :normal, :first_method
  o.add_step :normal, :another_method
  o.add_step :normal, :final_method
end
```

And finally we need to modify the method signature slightly to accept a hash. This hash contains information about the execution of the steps, and can also be leveraged to pass information from one step to another without altering the result. (We will cover this topic in more detail shortly)

[./spec/readme/example_1\_spec.rb](https://github.com/felixflores/railway_operation/blob/master/spec/readme/example_1_spec.rb)

```ruby
module Readme
  class Example1
    include RailwayOperation

    operation do |o|
      o.add_step :normal, :first_method
      o.add_step :normal, :another_method
      o.add_step :normal, :final_method
    end

    def initialize(someone = 'someone')
      @someone = someone
    end

    def first_method(argument, **)
      argument << "Hello #{@someone}, from first_method."
    end

    def another_method(argument, **)
      argument << 'Hello from another_method.'
    end

    def final_method(argument, **)
      argument << 'Hello from final_method.'
    end
  end
end
```

Now we can call the `.run` method on the class to yeild the same result.

```ruby
result, info = Readme::Example1.new('Felix').run(argument)

result == [
  'Hello Felix, from first_method.'
  'Hello from another_method.'
  'Hello from final_method.'
]
```

Additionally, if your class does not require any arguments in its initializer you can call.

```ruby
result, info = Readme::Example1.run(argument)
```

One important detail to call out here is that calling run returns the result object (which is the return value of the operation) and the info object which is a hash like object containing information about the execution of the operation. See 

## Multitrack Execution
Let's say we want to log an error in case something goes wrong along the execution chain. We can modify our class with the following

[./spec/readme/synopsis_spec.rb](https://github.com/felixflores/railway_operation/blob/master/spec/readme/synopsis_spec.rb)

```ruby
module Readme
  class FailingStep
    include RailwayOperation::Operator
    class MyError < StandardError; end

    fails_step << MyError

    add_step 0, :first_method
    add_step 0, :another_method
    add_step 0, :final_method
    add_step 1, :log_error                 # note that add_step's argument is 1

    ...

    def log_error(argument, info)
      error = info.failed_steps.last
      argument << "Error #{error[:error].class}"
    end
  end
end
```

If we changed `first_method` to

```ruby
def first_method(argument, **)
  argument << 'Hello from first_method.'
  raise MyError
end
```

And `ReadMe::FailingStep.run([])`, then `result` will be ['Error MyError']

Alternatively if we changed 

```ruby
def another_method(argument, **)
  argument << 'Hello from another_method.'
  raise MyError
end
```

`result` will be `['Hello somebody, from first_method.', 'Readme::FailingStep::MyError']`

In order to explain how this works, it's important to cover several key concepts. To declare a step at its simplest for, `add_step(<track_id>, <method>)` is used. In order to explain what those parameters means, it's important to define a few terms and concepts. 




## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/railway_operation. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

