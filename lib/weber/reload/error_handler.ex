defmodule Weber.Reload.ErrorHandler do

  def undefined_function(module, fun, args) do
    load_modules(module)
    :error_handler.undefined_function(module, fun, args)
  end

  def undefined_lambda(module, fun, args) do
    load_modules(module)
    :error_handler.undefined_lambda(module, fun, args)
  end

  defp load_modules(module) do
    case Code.ensure_loaded(module) do
      { :module, _ } -> :ok
      { :error, _ }  -> Weber.Reload.load_module(module)
    end
  end
end