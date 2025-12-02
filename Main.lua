--[[
    Main.lua
    Entry point for the modular obfuscator
    
    Usage:
        local Obfuscator = require("Main")
        local result = Obfuscator.obfuscate(sourceCode, config)
]]--

-- Module paths (change these to your actual paths)
local MODULE_PATH = "https://github.com/LOZENP/Xevix-Obfuscator-v1"

-- Load modules
local Lexer = loadstring(game:HttpGet(MODULE_PATH .. "Lexer.lua"))()
local Parser = loadstring(game:HttpGet(MODULE_PATH .. "Parser.lua"))()
local Transformer = loadstring(game:HttpGet(MODULE_PATH .. "Transformer.lua"))()
local Generator = loadstring(game:HttpGet(MODULE_PATH .. "Generator.lua"))()

local Obfuscator = {}

-- Default configuration
Obfuscator.defaultConfig = {
    -- Transformer options
    renameVariables = true,
    renameFunctions = true,
    encryptStrings = false,
    prefix = "_",
    
    -- Generator options
    minify = false,
    watermark = "Obfuscated Script",
    
    -- Output options
    verbose = true
}

-- Main obfuscation function
function Obfuscator.obfuscate(source, userConfig)
    -- Merge configs
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
    
    -- Step 1: Lexical Analysis (Tokenization)
    if config.verbose then
        print("\n[1/4] Lexer: Tokenizing source code...")
    end
    
    local lexer = Lexer.new(source)
    local tokens = lexer:tokenize()
    
    if config.verbose then
        print(string.format("  ✓ Generated %d tokens", #tokens))
    end
    
    -- Step 2: Syntax Analysis (Parsing)
    if config.verbose then
        print("\n[2/4] Parser: Building AST...")
    end
    
    local parser = Parser.new(tokens)
    local ast = parser:parse()
    
    if config.verbose then
        print("  ✓ AST built successfully")
    end
    
    -- Step 3: Transformation (Obfuscation)
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
    
    -- Step 4: Code Generation
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

-- Convenience function for quick obfuscation
function Obfuscator.quick(source)
    return Obfuscator.obfuscate(source, {
        verbose = false
    })
end

return Obfuscator
