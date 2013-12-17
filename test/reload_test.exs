defmodule Weber.Reload.Test do
  use ExUnit.Case

  def root_path do
    Path.expand("support/reload", __DIR__)
  end

  setup_all do
    Weber.Reload.start(root_path)
    :ok
  end

  setup do
    Weber.Reload.enable
    :ok
  end

  teardown_all do
    Weber.Reload.stop
    :ok
  end

  test "reload files" do
    assert Weber.Foo.foo == 1
    assert Bar.bar == 1

    #Check if not update file yet
    assert Weber.Reload.purge == :ok

    File.touch!(root_path <> "/foo.ex")

    assert Weber.Reload.purge == :purged

    assert Weber.Foo.foo == 1
    assert Bar.bar == 1
  end
end