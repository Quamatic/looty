local Symbol = {}

function Symbol.named(name: string)
	local symbol = newproxy(true)

	getmetatable(symbol).__tostring = function()
		return string.format("Symbol(%s)", name)
	end

	return symbol
end

return Symbol