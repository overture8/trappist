# A Light Wrapper for Mnesia

I love the idea of Mnesia, but I've always found it a bit opaque, so I made this little wrapper. If you don't know what Mnesia is - it's Erlang's built-in data store. It stores Erlang data structures (and primitives) directly, there is no type resolution required.

## Is This a Good Idea? Does Mnesia Scale?

I don't know if it's a good idea, honestly. I _think_ it scales... RabbitMQ uses it for persistence as do many gigantic companies. It's incredibly fast as well, and is ACID compliant and distributed. That said, it also has a reputation for being "corruptible", which is something I'm still investigating.

What I've found so far is that if you use memory-based storage, you're fine. This might sound weird but the deal is that Erlang doesn't like to come down, and if you go with a distributed VM ring, it likely won't. This is where Mnesia works best: within a cluster of Erlang VMs that can reliably support a distributed data structure.

If, however, you run Mnesia on a single node (which will probably work for you very well), you can run into a situation where Mnesia has not copied some data to disk (it does this in a background process) when the VM goes down, therefore you might lose that data. You can see this clearly when running tests. The suite might finish and you might go looking for your test data, only to see that it's not there because the tests finished so fast that the write process didn't happen.

### Wait, Didn't You Just Say ACID?

Yeah. This is the part I'm still diving into. I always assumed "Durability" meant that it was stored on disk somewhere, but that's in the realm (I think) of non-distributed applications. In Erlang land, ACID refers to a distributed system and data being available when a transaction completes.

### So, Is This A Good Idea or What?

I think so, and here's why: _you can get your app off the ground in super short order_. I've tried to make this look and act a bit like Ecto, so when you decide to flip your code over to Postgres (should you ever) then it's a quick refactor. I still have some work to do on that front - but in general I think developing against Mnesia is delightful. 

## Code?

Start with the configuration:

```elixir
config :trappist, 
  storage: [
    dir: "/Users/rob/mnesia/trappist/dev/",
    node: [node()]
  ]
```

This tells Mnesia where to put the data and which node to run on. The default is the current node, and you don't need to specify it. You **absolutely should** specify a data directory, especially if you push this to staging or take it live. Mnesia stores its data in a directory on disk (if that's what you choose), and you don't want that overwritten when you push your code live.

You define a table (Mnesia's term) like this:

```elixir
defmodule Planet do
  use Trappist.Table, [
    name: :planets, 
    attributes: [
      id: :auto, 
      name: "",
      diameter: 0,
      type: nil
    ], 
    index: [:name]
  ]
end
```

You now have these things:

 - A struct called `Planet` which you can work with
 - An auto-incrmenting integer id. You can also specify a `:uuid`
 - Defaults on that struct that correspond to your attributes
 - Indexes on attributes to make querying easier

You can now save things transactionally:

```elixir
%Planet{name: "Flipper", diameter: 12, type: "rocky"} |> Planet.save
%Planet{name: "Earth", diameter: 20, type: "gassy"} |> Planet.save
%Planet{name: "Mars", diameter: 4, type: "rocky"} |> Planet.save
```

You can save things in bulk, transactionally as well:

```elixir
[
  %Moon{name: "Moon 1"},
  %Moon{name: "Moon 2"},
  %Moon{name: "Moon 3"},
  %Moon{name: "Moon 4"},
  %Moon{name: "Moon 5"},
] |> Moon.save
```

You can query the data by id:

```elixir
planet = Planet.find(1)
```

You can do miscellaneous things, like get a count, first and last:

```elixir
count = Planet.count
first = Planet.first
last = Planet.last
```

You can query by index:

```elixir
 planets = Planet.search_index :name, "Earth"
```

You can use `match_object`, which I'm still not sure about in terms of utility:

```elixir
Planet.pattern(type: "rocky") 
|> Planet.match
```

Or you can just do a simple `select`, which is wonky in Mnesia but I tried to make it nicer:

```elixir
planets = Planet.where(type: "rocky")
```

If you need all the records back, you can do that too:

```elixir
planets = Planet.match #not sure about this name yet
```

Finally, to delete a record:

```elixir
Planet.delete(1)
```

## API In Progress

If you're thinking this looks very ActiveRecordy, yeah, I think it does. I wanted to chase the idea of working with structs that persisted their state, and this is what I came up with. That said, I think I'd like to change that.

I'm thinking about going with a repository style interface, but I don't care for those very much. I'm also thinking of separating things the way Ecto does and basically copying their entire way of doing things so all you need to do is to swap out `use Trappist` with `use Ecto` or something.

## Why The Name Trappist?

Trappist is a style of beer as well as a very old Catholic order. Trappist monks brew the best beers in the world, and this reminds me of working with Elixir and Mnesia. The language (Elixir) and the framework underneath (OTP) are intoxicating, just like a wonderful Westvlateren XII. Mnesia is ceremonial, baroque, and an artifact of an older time... sort of like the Catholic church.

## I Need Help

I wrote this up this last weekend as something fun to do. The weather here in Seattle sucks, and it's fun to tweak out sometimes. I could _really_ use some help refactoring - the code right now works, but it really needs tests and cleaning up, which I'll do in the coming weeks.

If you want to help out, let me know!