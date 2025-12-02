--[[
    Main.lua
    Entry point for the modular obfuscator
]]--

local MODULE_PATH = "https://raw.githubusercontent.com/LOZENP/Xevix-Obfuscator-v1/main/"

-- Load modules with error handling
local function loadModule(name)
    local url = MODULE_PATH .. name .. ".lua"
    local success, content = pcall(function()
        return game:HttpGet(url)
    end)
    
    if not success then
        error("Failed to download " .. name .. ": " .. tostring(content))
    end
    
    local func, err = loadstring(content)
    if not func then
        error("Failed to compile " .. name .. ": " .. tostring(err))
    end
    
    return func()
end

print("Loading modules...")
local Lexer = loadModule("Lexer")
local Parser = loadModule("Parser")
local Transformer = loadModule("Transformer")
local Generator = loadModule("Generator")
print("All modules loaded successfully!")

local Obfuscator = {}

Obfuscator.defaultConfig = {
    renameVariables = true,
    renameFunctions = true,
    encryptStrings = false,
    prefix = "_",
    minify = false,
    watermark = "Obfuscated Script",
    verbose = true
}

function Obfuscator.obfuscate(source, userConfig)
    local config = {}
    for k, v in pairs(Obfuscator.defaultConfig) do
        config[k] = v
    end
    if userConfig then
        for k, v in pairs(userConfig) do
            config[k] = v
        end
    end
    
    local startTime = tick()
    
    if config.verbose then
        print("========================================")
        print("  Modular Lua Obfuscator")
        print("========================================")
    end
    
    if config.verbose then
        print("\n[1/4] Lexer: Tokenizing source code...")
    end
    
    local lexer = Lexer.new(source)
    local tokens = lexer:tokenize()
    
    if config.verbose then
        print(string.format("  ✓ Generated %d tokens", #tokens))
    end
    
    if config.verbose then
        print("\n[2/4] Parser: Building AST...")
    end
    
    local parser = Parser.new(tokens)
    local ast = parser:parse()
    
    if config.verbose then
        print("  ✓ AST built successfully")
    end
    
    if config.verbose then
        print("\n[3/4] Transformer: Obfuscating AST...")
        if config.renameVariables then
            print("  • Renaming variables")
        end
        if config.renameFunctions then
            print("  • Renaming functions")
        end
        if config.encryptStrings then
            print("  • Encrypting strings")
        end
    end
    
    ast = Transformer.transform(ast, config)
    
    if config.verbose then
        print("  ✓ AST transformed")
    end
    
    if config.verbose then
        print("\n[4/4] Generator: Generating output...")
    end
    
    local output = Generator.generate(ast, config)
    
    if config.verbose then
        print("  ✓ Code generated")
    end
    
    local endTime = tick()
    
    if config.verbose then
        print("\n========================================")
        print(string.format("  Completed in %.3f seconds", endTime - startTime))
        print(string.format("  Original size: %d bytes", #source))
        print(string.format("  Output size: %d bytes", #output))
        print(string.format("  Size increase: %.1f%%", ((#output / #source) - 1) * 100))
        print("========================================\n")
    end
    
    return output
end

function Obfuscator.quick(source)
    return Obfuscator.obfuscate(source, {
        verbose = false
    })
end

return Obfuscator
