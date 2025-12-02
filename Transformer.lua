--[[
    Transformer.lua
    Transforms and obfuscates the AST
]]--

local Transformer = {}

-- Configuration
Transformer.config = {
    renameVariables = true,
    renameFunctions = true,
    encryptStrings = false,
    prefix = "_"
}

-- Generate random identifier
function Transformer.randomIdentifier(length)
    length = length or math.random(10, 16)
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local result = chars:sub(math.random(1, 52), math.random(1, 52))
    
    chars = chars .. "0123456789_"
    for i = 1, length - 1 do
        result = result .. chars:sub(math.random(1, #chars), math.random(1, #chars))
    end
    
    return result
end

-- Encrypt string (simple XOR for now)
function Transformer.encryptString(str, key)
    key = key or 123
    local encrypted = {}
    
    for i = 1, #str do
        local byte = string.byte(str, i)
        table.insert(encrypted, byte ~ key)
    end
    
    return encrypted
end

-- Transform AST
function Transformer.transform(ast, config)
    config = config or Transformer.config
    
    -- Scope tracking for variable renaming
    local scopes = {{}}
    local renameMap = {}
    
    local function pushScope()
        table.insert(scopes, {})
    end
    
    local function popScope()
        table.remove(scopes)
    end
    
    local function getCurrentScope()
        return scopes[#scopes]
    end
    
    local function registerVariable(name)
        if not renameMap[name] then
            renameMap[name] = config.prefix .. Transformer.randomIdentifier()
        end
        getCurrentScope()[name] = renameMap[name]
    end
    
    local function resolveVariable(name)
        -- Check from innermost to outermost scope
        for i = #scopes, 1, -1 do
            if scopes[i][name] then
                return scopes[i][name]
            end
        end
        return name -- Not found, keep original (might be global)
    end
    
    -- Recursive transformer
    local function transformNode(node)
        if not node then return node end
        
        if node.type == "Program" then
            for i, stmt in ipairs(node.body) do
                node.body[i] = transformNode(stmt)
            end
            
        elseif node.type == "LocalDeclaration" then
            -- Transform values first
            for i, value in ipairs(node.values) do
                node.values[i] = transformNode(value)
            end
            
            -- Register and rename variables
            if config.renameVariables then
                for i, name in ipairs(node.names) do
                    registerVariable(name)
                    node.names[i] = renameMap[name]
                end
            end
            
        elseif node.type == "LocalFunction" then
            if config.renameFunctions then
                registerVariable(node.name)
                node.name = renameMap[node.name]
            end
            
            pushScope()
            
            -- Register parameters
            if config.renameVariables then
                for i, param in ipairs(node.parameters) do
                    registerVariable(param)
                    node.parameters[i] = renameMap[param]
                end
            end
            
            -- Transform body
            for i, stmt in ipairs(node.body) do
                node.body[i] = transformNode(stmt)
            end
            
            popScope()
            
        elseif node.type == "Identifier" then
            if config.renameVariables then
                node.name = resolveVariable(node.name)
            end
            
        elseif node.type == "CallExpression" then
            -- Don't rename built-in functions
            local builtins = {
                "print", "warn", "error", "assert", "type", "tostring",
                "tonumber", "pairs", "ipairs", "next", "select", "loadstring"
            }
            
            local isBuiltin = false
            for _, builtin in ipairs(builtins) do
                if node.callee == builtin then
                    isBuiltin = true
                    break
                end
            end
            
            if not isBuiltin and config.renameFunctions then
                node.callee = resolveVariable(node.callee)
            end
            
            -- Transform arguments
            for i, arg in ipairs(node.arguments) do
                node.arguments[i] = transformNode(arg)
            end
            
        elseif node.type == "StringLiteral" then
            if config.encryptStrings then
                local encrypted = Transformer.encryptString(node.value)
                node.encrypted = encrypted
                node.isEncrypted = true
            end
            
        elseif node.type == "BinaryExpression" then
            node.left = transformNode(node.left)
            node.right = transformNode(node.right)
            
        elseif node.type == "ReturnStatement" then
            for i, value in ipairs(node.values) do
                node.values[i] = transformNode(value)
            end
        end
        
        return node
    end
    
    return transformNode(ast)
end

return Transformer
