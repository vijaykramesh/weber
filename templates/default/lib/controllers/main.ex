defmodule #{proj}.Main do

  def action("GET", []) do
    {:render, [project: "#{projectName}"], []}
  end
        
end
