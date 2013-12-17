defmodule Weber.Reload do
  use GenServer.Behaviour

  defrecord Config, root_path: nil, load_modules: [], load_time: { { 1970, 1, 1 }, { 0, 0, 0 } }

  def start(root) do
    unless Process.whereis(__MODULE__) do
      { :module, _ } = Code.ensure_loaded(Weber.Reload.ErrorHandler)
      Weber.Supervisor.start_child(Weber.Supervisor, __MODULE__, [root])
    end
  end

  def start_link(root_path) do
    config = Config.new(root_path: root_path)
    :gen_server.start({ :local, __MODULE__ }, __MODULE__, config, [])
  end

  def init(config) do
    { :ok, config }
  end

  def handle_call(:root_path, _from, config) do
    { :reply, config.root_path, config }
  end

  def handle_call(:load_modules, _from, config) do
    { :reply, config.load_modules, config }
  end

  def handle_call(:purge_modules, _from, Config[root_path: root_path, load_modules: load_modules, load_time: load_time] = config) do
    paths = Path.wildcard(root_path <> "/**/*.ex") -- Path.wildcard(root_path <> "/templates/**/*.ex")
    last_file_update = Enum.reduce(paths, load_time, &(last_file_reload_time(&1, &2)))

    if load_time == last_file_update do
      {:reply, :ok, config}
    else
      purge_modules(load_modules)
      Code.unload_files(paths)
      {:reply, :purged, config.load_modules([]).load_time(last_file_update)}
    end
  end

  def handle_call(:stop, _from, config) do
    { :stop, :normal, :ok, config }
  end

  def stop do
    :gen_server.call(__MODULE__, :stop)
  end

  def handle_cast({:append_module, module, file}, Config[load_time: load_time] = config) do
    last_file_update = last_file_reload_time(file, load_time)
    {:noreply, config.load_time(last_file_update).update_load_modules(&(&1 ++ [module]))}
  end

  def enable do
    if Process.whereis(__MODULE__) do
      Process.put(:elixir_ensure_compiled, true)
      Process.flag(:error_handler, Weber.Reload.ErrorHandler)
      :ok
    end
  end

  def purge do
    :gen_server.call(__MODULE__, :purge_modules)
  end

  def load_module(module) do
    case atom_to_binary(module) do
      "Elixir." <> _ ->
        root_path = :gen_server.call(__MODULE__, :root_path)
        paths = Path.wildcard(root_path <> "/**/*.ex") -- Path.wildcard(root_path <> "/templates/**/*.ex")
        try do
          Kernel.ParallelCompiler.files(paths, [each_module: fn(file, module, _bytecode) -> add_to_config(module, file) end])
        catch
          kind, reason ->
            :erlang.raise(kind, reason, System.stacktrace)
        end
      _ -> :not_found
    end
  end

  defp add_to_config(module, file) do
    :gen_server.cast(__MODULE__, { :append_module, module, file })
  end

  defp last_file_reload_time(file, load_time) do
    case File.stat(file) do
      { :ok, File.Stat[mtime: mtime] } -> max(mtime, load_time)
      { :error, _ } -> load_time
    end
  end

  defp purge_modules(modules) do
    Enum.each modules, fn(mod) ->
      :code.purge(mod)
      :code.delete(mod)
    end
  end

end