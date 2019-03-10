---
-- Crate is a fancy name for Flux libraries
--
-- This library is the centralized controlling mechanism for them.

if Crate then return end

if !string.ensure_end then
  include 'flux/gamemode/lib/flow/lib/sh_aliases.lua'
  include 'flux/gamemode/lib/flow/lib/sh_string.lua'
end

if !table.safe_merge then
  include 'flux/gamemode/lib/flow/lib/sh_table.lua'
end

include 'classes/sh_package.lua'

local crate_metadata = {}

if SERVER then
  fl.shared.crates = {}
else
  crate_metadata = fl.shared.crates
end

Crate           = {}
Crate.installed = {}
Crate.current   = nil

local search_paths = {
  ['flux/gamemode/lib/']      = true,
  [fl.schema..'/schema/lib/'] = true,
  ['lua/_flux/packages/']     = true
}

--- Adds a search path relative to 'LUA' system.
-- @return [Table(self)]
function Crate:add_path(path)
  search_paths[path:ensure_end('/')] = true

  return self
end

--- Describes current package's specification.
-- For every singular function there is a plural alias and vice versa.
-- ```
-- Crate:describe(function(s)
--   s.name        'Example Package'
--   s.version     '1.0'
--   s.date        '2019-03-09'
--   s.summary     'Brief summary of what the package does.'
--   s.description 'A more detailed description of what the package does.'
--   s.authors     { 'Flux Developer' }
--   s.email       'example@example.com'
--   s.files       { 'lib/example.lua', 'config/example.lua' }
--   s.global      'ExamplePackage'
--   s.website     'https://example.com'
--   s.license     'MIT'
--
--   s.depends     'random_dependency'
--
--   if IS_DEVELOPMENT then
--     s.depends   'random_development_package'
--   end
-- end)
-- ```
-- @return [Package]
function Crate:describe(callback)
  callback(self.current)

  local meta = self.current.metadata

  if istable(meta.global) then
    for k, v in ipairs(meta.global) do
      _G[v] = _G[v] or {}
    end
  elseif isstring(meta.global) then
    _G[meta.global] = _G[meta.global] or {}
  end

  local full_path = meta.full_path

  if istable(meta.file) then
    for k, file in ipairs(meta.file) do
      local filename = file:file_from_filename()

      if filename:starts('sv') or filename:starts('cl') or filename:starts('sh') then
        util.include(full_path..file)
      else
        include(full_path..file)
      end
    end
  elseif isstring(meta.file) then
    local file = meta.file
    local filename = file:file_from_filename()

    if filename:starts('sv') or filename:starts('cl') or filename:starts('sh') then
      util.include(full_path..file)
    else
      include(full_path..file)
    end
  end

  return self.current
end

--- Determines if the package has already been installed.
-- @return [Boolean]
function Crate:included(name)
  return istable(self.installed[name])
end

Crate.present       = Crate.included
Crate.is_installed  = Crate.included

do
  local function do_include(file_path, lib_path, full_path)
    Crate.current = Package.new(file_path, lib_path, full_path)
    CRATE = Crate.current

    if CLIENT then
      Crate.current.metadata = crate_metadata[lib_path]
      Crate:describe()
    else
      include(file_path)
      fl.shared.crates[lib_path] = table.Copy(Crate.current.metadata)
    end

    Crate.installed[lib_path] = Crate.current

    Crate.current = nil
    CRATE         = nil
  end

  --- Attempts to include the package with the specified name.
  -- This function will look for the package in the search paths that have previously been added.
  -- If no package with the matching name can be found, throws an error.
  -- @return [...]
  function Crate:include(lib_path)
    if SERVER then
      local folder_path = lib_path:ensure_end('/')
      local files, _ = file.Find(folder_path..'*.cratespec', 'LUA')

      if !istable(files) or #files == 0 then
        for path, v in pairs(search_paths) do
          local full_path = path..folder_path:ensure_end('/')
          local files, _ = file.Find(full_path..'*.cratespec', 'LUA')

          if istable(files) and #files > 0 then
            return do_include(full_path..files[1], lib_path, full_path)
          end
        end

        error('could not load "'..lib_path..'" (no crate spec file found)')
      elseif istable(files) and #files > 0 then
        return do_include(folder_path..files[1], lib_path, folder_path)
      else
        error('could not load "'..lib_path..'" (library not found)')
      end
    else
      return do_include(crate_metadata[lib_path].file_path, lib_path, lib_path)
    end
  end
end
