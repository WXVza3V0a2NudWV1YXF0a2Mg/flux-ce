﻿local COMMAND = Command.new('charsetmodel')
COMMAND.name = 'CharSetModel'
COMMAND.description = 'command.char_set_model.description'
COMMAND.syntax = 'command.char_set_model.syntax'
COMMAND.permission = 'assistant'
COMMAND.category = 'permission.categories.character_management'
COMMAND.arguments = 2
COMMAND.player_arg = 1
COMMAND.aliases = { 'setmodel' }

function COMMAND:on_run(player, targets, model)
  for k, v in ipairs(targets) do
    v:notify('notification.model_changed', model)
    Characters.set_model(v, model)
  end

  self:notify_staff('command.command.charsetmodel.message', {
    player = get_player_name(player),
    target = util.player_list_to_string(targets),
    model = model
  })
end

COMMAND:register()
