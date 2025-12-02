--[[
    Generator.lua
    Generates Lua code from the transformed AST
]]--

local Generator = {}

Generator.config = {
    minify = false,
    watermark = nil
}

function Generator.generate(ast, config)
    config = config or Generator.config
    
    local output = ""
    local indent = ""
    
    -- Add watermark
    if config.watermark then
        output = output .. "--[[\n"
        output = output .. "    " .. config.watermark .. "\n"
        output = output .. "    Obfuscated with Modular Lua Obfuscator\n"
        output = output .. "]]--\n\n"
    end
    
    local function addIndent()
        if not config.minify then
            indent = indent .. "    "
        end
    end
    
    local function removeIndent()
        if not config.minify then
            indent = indent:sub(1, -5)
        end
    end
    
    local function newline()
        if config.minify then
            return " "
        else
            return "\n"
        end
    end
    
    local function space()
        if config.minify then
            return ""
        else
            return " "
        end
    end
    
    -- Generate code from AST node
    local function gen(node)
        if not node then return "" end
        
        if node.type == "Program" then
            for _, stmt in ipairs(node.body) do
                output = output .. gen(stmt)
            end
            
        elseif node.type == "LocalDeclaration" then
            output = output .. indent .. "local " .. table.concat(node.names, ", ")
            
            if #node.values > 0 then
                output = output .. space() .. "=" .. space()
                
                local vals = {}
                for _, value in ipairs(node.values) do
                    table.insert(vals, gen(value))
                end
                output = output .. table.concat(vals, "," .. space())
            end
            
            output = output .. newline()
            
        elseif node.type == "LocalFunction" then
            output = output .. indent .. "local function " .. node.name .. "("
            output = output .. table.concat(node.parameters, "," .. space()) .. ")"
            output = output .. newline()
            
            addIndent()
            for _, stmt in ipairs(node.body) do
                output = output .. gen(stmt)
            end
            removeIndent()
            
            output = output .. indent .. "end" .. newline()
            
        elseif node.type == "ReturnStatement" then
            output = output .. indent .. "return"
            
            if #node.values > 0 then
                output = output .. space()
                local vals = {}
                for _, value in ipairs(node.values) do
                    table.insert(vals, gen(value))
                end
                output = output .. table.concat(vals, "," .. space())
            end
            
            output = output .. newline()
            
        elseif node.type == "CallExpression" then
            local result = node.callee .. "("
            
            local args = {}
            for _, arg in ipairs(node.arguments) do
                table.insert(args, gen(arg))
            end
            result = result .. table.concat(args, "," .. space()) .. ")"
            
            if not output:match("%S$") then
                -- This is a statement, not an expression
                output = output .. indent .. result .. newline()
            else
                return result
            end
            
        elseif node.type == "Identifier" then
            return node.name
            
        elseif node.type == "StringLiteral" then
            if node.isEncrypted and node.encrypted then
                -- Generate decryption code
                local bytes = table.concat(node.encrypted, ",")
                return string.format("(function()local t={%s}local s=''for i=1,#t do s=s..string.char(t[i]~123)end return s end)()", bytes)
            else
                return '"' .. node.value:gsub('"', '\\"'):gsub('\n', '\\n') .. '"'
            end
            
        elseif node.type == "NumberLiteral" then
            return tostring(node.value)
            
        elseif node.type == "BooleanLiteral" then
            return tostring(node.value)
            
        elseif node.type == "NilLiteral" then
            return "nil"
            
        elseif node.type == "BinaryExpression" then
            local left = gen(node.left)
            local right = gen(node.right)
            return left .. space() .. node.operator .. space() .. right
        end
        
        return ""
    end
    
    gen(ast)
    return output
end

return Generator
