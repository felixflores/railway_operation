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
  class Example1
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
argument = ex1.first_method(argument)
argument = ex1.another_method(argument)
result = ex1.final_method(argument)

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
      o.add_step 1, :first_method
      o.add_step 1, :another_method
      o.add_step 1, :final_method
    end
```

Before we can take advantage of RailwayOperation we need to modify our method signatures slightly from `def first_method(argument)` to `def first_method(arugment, **)`. This allows our methods to accept an addtional has called info (we will cover this topic of `info` in more detail shortly)

[./spec/readme/example_1\_spec.rb](https://github.com/felixflores/railway_operation/blob/master/spec/readme/example_1_spec.rb)

```ruby
module Readme
  class Example1
    include RailwayOperation

    operation do |o|
      o.add_step 1, :first_method
      o.add_step 1, :another_method
      o.add_step 1, :final_method
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
arugment = []
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

result == [
  'Hello someone, from first_method.',
  'Hello from another_method.',
  'Hello from final_method.'
]
```

One important detail to call out here is that calling run returns the `result` object (which is the return value of the operation) and an `info` object which is a hash like object containing information about the execution of the operation. To see a brief overview of the types of information `info` see [./spec/readme/example\_1_spec.rb](https://github.com/felixflores/railway_operation/blob/master/spec/readme/example_1_spec.rb)

A more detailed explanation of `info` is on the [RailwayOperation: Info](https://github.com/felixflores/railway_operation#info) section.

## Multitrack Execution
So far we've seen a single track execution of an operation. The track is the first argument of the `add_step` method. In our previous example all our steps executed on track 1.

![basic - page 1](https://user-images.githubusercontent.com/65030/38450687-5067bd94-39f0-11e8-9b85-198ba7b28b1b.png)


Let's now consider the following example

```ruby
module Readme
  class Example2_1
    include RailwayOperation

    operation do |o|
      o.add_step 1, :method_1
      o.add_step 1, :method_2
      o.add_step 2, :method_3
      o.add_step 2, :method_4
    end

    def initialize(someone = 'someone')
      @someone = someone
    end

    def method_1(argument, **)
      argument << 1
    end

    def method_2(argument, **)
      argument << 2
    end

    def method_3(argument, **)
      argument << 3
    end

    def method_4(argument, **)
      argument << 4
    end
  end
end
```

When we invoke `run` this we'll get the following result.

```ruby
result, _info = Readme::Example2_1.run([])
result == [1, 2]
```

What happened here? Instead of `method_3` and `method_4` being on track one, they are now set to execute on track 2. So when we ran the operation it only ran the methods on track one.

![example 2 1 - page 1 1](https://user-images.githubusercontent.com/65030/38447196-f4b65800-39c9-11e8-94fc-310c4931d7fb.png)

In order to change the execution path of the operation to track 2 we need to introduce a new concept called `stepper_function`. The `stepper_function` is responsible for executing each step of the operation and deciding the direction of next step of the operation.

```
operation do |o|
  o.stepper_function do |stepper, _, &step|
    argument, _ = step.call

    if argument.length >= 2
      stepper.switch_to(2)
    end

    stepper.continue
  end

  o.add_step 1, :method_1
  o.add_step 1, :method_2
  o.add_step 2, :method_3
  o.add_step 2, :method_4
end
```

Now, when we call run we get the folling result.

```ruby
argument = []
result, _info = Readme::Example2_2.run(argument)
result == [1, 2, 3, 4]
```

![example 2 2 - page 1](https://user-images.githubusercontent.com/65030/38449378-5b1c6ac8-39dc-11e8-9cf9-f9e5c1a40cb6.png)

For now you can think of the `stepper_function` as a `lambda` that surrounds a step (this is not entirely accurate, but it's good enough for now). This `lambda` has the following shape.

```ruby
lambda do |stepper, info, &step|

  ...

end
```

The `stepper` argument is control structure that dictates the movement of the execution. 

```ruby
stepper.continue
stepper.switch_to(specified_track)
stepper.fail_step
stepper.successor_track
stepper.halt_operation
stepper.fail_operation
```
In our example we used the `switch_to` and `continue` methods to switch from track 1 to 2 and continue the execution of our operation.

The `info` argument is the same `info` object we've seen from calling `run`, it is passed from one step to another.

Finally, `step` is a `lambda` which runs the step once called. Overlayed on top of our previous diagram, it would roughly look like this.

![example 2 2 info - page 1](https://user-images.githubusercontent.com/65030/38450987-c93630ac-39f5-11e8-96cc-283fd00ff5ab.png)

To overlay the `stepper_function` in our example more concretely, looks something like this.

![example 2 2 decisions - page 1 2](https://user-images.githubusercontent.com/65030/38451168-33f5fc12-39f9-11e8-9b5f-6e6e979afe0f.png)


## Info

TODO

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/railway_operation. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

