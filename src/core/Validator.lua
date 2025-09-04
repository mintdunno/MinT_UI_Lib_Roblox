-- Validator: basic script validation helpers (lightweight static checks)
-- API:
-- Validator.basicSyntax(text) -> ok:boolean, errInfo? { line, col, msg }

local Validator = {}

-- Very lightweight checks: bracket balance and unclosed quotes
function Validator.basicSyntax(text)
	local stack = {}
	local line = 1
	local col = 0
	local inString = false
	local stringChar = nil -- '"' or '\''
	local escape = false

	local opens = { ['(']=')', ['{']='}', ['[']=']' }
	local closes = { [')']=true, ['}']=true, [']']=true }

	for i = 1, #text do
		local ch = string.sub(text, i, i)
		if ch == '\n' then
			line += 1
			col = 0
		else
			col += 1
		end

		if inString then
			if escape then
				escape = false
			elseif ch == '\\' then
				escape = true
			elseif ch == stringChar then
				inString = false
				stringChar = nil
			end
		else
			if ch == '"' or ch == '\'' then
				inString = true
				stringChar = ch
			elseif opens[ch] then
				table.insert(stack, { ch = ch, line = line, col = col })
			elseif closes[ch] then
				local top = stack[#stack]
				if not top or opens[top.ch] ~= ch then
					return false, { line = line, col = col, msg = "Unmatched closing bracket '"..ch.."'" }
				end
				stack[#stack] = nil
			end
		end
	end

	if inString then
		return false, { line = line, col = col, msg = "Unterminated string literal" }
	end
	if #stack > 0 then
		local top = stack[#stack]
		return false, { line = top.line, col = top.col, msg = "Unclosed bracket '"..top.ch.."'" }
	end
	return true
end

return Validator

