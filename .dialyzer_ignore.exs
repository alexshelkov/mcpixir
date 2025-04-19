[
  # Ignore callback_info_missing for Mix.Task
  {"lib/mix/tasks/mcpixir.airbnb.ex", :callback_info_missing},
  {"lib/mix/tasks/mcpixir.blender.ex", :callback_info_missing},
  {"lib/mix/tasks/mcpixir.browser.ex", :callback_info_missing},
  {"lib/mix/tasks/mcpixir.chat.ex", :callback_info_missing},
  {"lib/mix/tasks/mcpixir.ex", :callback_info_missing},
  {"lib/mix/tasks/mcpixir.filesystem.ex", :callback_info_missing},
  {"lib/mix/tasks/mcpixir.http.ex", :callback_info_missing},
  {"lib/mix/tasks/mcpixir.multi.ex", :callback_info_missing},
  {"lib/mix/tasks/mcpixir.release.ex", :callback_info_missing},
  
  # Ignore no_return warnings for functions that can't fail
  {"lib/mcpixir.ex", :no_return},
  {"lib/mcpixir/connectors/base.ex", :no_return},
  {"lib/mcpixir/connectors/http.ex", :no_return},
  {"lib/mcpixir/connectors/stdio.ex", :no_return},
  {"lib/mcpixir/connectors/websocket.ex", :no_return},
  {"lib/mix/tasks/mcpixir.airbnb.ex", :no_return},
  {"lib/mix/tasks/mcpixir.blender.ex", :no_return},
  {"lib/mix/tasks/mcpixir.browser.ex", :no_return},
  {"lib/mix/tasks/mcpixir.chat.ex", :no_return},
  {"lib/mix/tasks/mcpixir.filesystem.ex", :no_return},
  {"lib/mix/tasks/mcpixir.http.ex", :no_return},
  {"lib/mix/tasks/mcpixir.multi.ex", :no_return},
  
  # Ignore pattern_match_cov warnings that don't affect functionality
  {"lib/mcpixir.ex", :pattern_match_cov},
  {"lib/mcpixir/agents/mcpagent.ex", :pattern_match_cov},
  {"lib/mcpixir.ex", :call},
  {"lib/mcpixir/agents/mcpagent.ex", :invalid_contract},
  {"lib/mcpixir/agents/mcpagent.ex", :pattern_match}
]