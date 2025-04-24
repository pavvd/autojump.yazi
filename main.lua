local function trim_string(s)
  if type(s) ~= "string" then return s end
  return string.match(s, "^%s*(.-)%s*$")
end

local function run_autojump(term)
	local child, err = Command("autojump")
		:arg(term)
		:stdout(Command.PIPED)
		:stderr(Command.PIPED)
		:spawn()

	if not child then
		return { err = string.format("Failed to spawn `autojump %s`: %s", term, err) }
	end

	local output, wait_err = child:wait_with_output()
	if not output then
		return { err = string.format("Failed to read `autojump %s` output: %s", term, wait_err) }
	end

	local stdout_str = trim_string(output.stdout)
	local stderr_str = trim_string(output.stderr)

	if not output.status.success then
		local err_msg
		if #stderr_str > 0 then
			if stderr_str:find("No matching directory found") or stderr_str:find("does not exist") or stderr_str:find("cdshell: no such directory") then
				err_msg = string.format("Autojump: No directory found for '%s'", term)
			else
				err_msg = string.format("`autojump` failed: %s", stderr_str)
			end
		else
			err_msg = string.format("`autojump` exited with status %s (no stderr)", output.status.code or "unknown")
		end
		return { err = err_msg }
	end

	if #stdout_str == 0 then
		return { err = string.format("Autojump succeeded but returned empty path for '%s'", term) }
	end

	return { path = stdout_str }
end

return {
  entry = function()
    local text_value, event_code = ya.input({
      title = "Autojump to:",
      position = { "top-center", y = 15, w = 50 },
    })

    if event_code ~= 1 then
      return
    end

    if type(text_value) ~= "string" then
       ya.notify({ title = "Autojump Plugin Error", content = "Internal error: input value not a string", level = "error", timeout = 5 })
       return
    end

    -- Trim the input using manual function
    local term = trim_string(text_value)

    -- Check if the input was empty after trimming
    if #term == 0 then
      ya.notify({ title = "Autojump", content = "No jump phrase provided", level = "warn", timeout = 3 })
      return
    end

    -- Run autojump
    local result = run_autojump(term)

    if result.err then
      ya.notify({ title = "Autojump Error", content = result.err, level = "error", timeout = 5 })
      return
    end

    -- Validate the path received from autojump
    local target_url = Url(result.path)
    local cha = fs.cha(target_url)

    if not cha then
      local err_msg = string.format("Path not found: %s", result.path)
      ya.notify({ title = "Autojump Error", content = err_msg, level = "error", timeout = 5})
      return
    elseif not cha.is_dir then
      local err_msg = string.format("Path is not a directory: %s", result.path)
      ya.notify({ title = "Autojump Error", content = err_msg, level = "error", timeout = 5})
      return
    end

    ya.manager_emit("cd", { target_url })

  end,
}
