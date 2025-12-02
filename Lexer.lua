--[[
    Lexer.lua
    Tokenizes Lua source code into tokens
]]--

local Lexer = {}
Lexer.__index = Lexer

function Lexer.new(source)
    local self = setmetatable({}, Lexer)
    self.source = source
    self.pos = 1
    self.line = 1
    self.col = 1
    return self
end

function Lexer:peek(offset)
    offset = offset or 0
    return self.source:sub(self.pos + offset, self.pos + offset)
end

function Lexer:consume()
    local char = self:peek()
    self.pos = self.pos + 1
    if char == '\n' then
        self.line = self.line + 1
        self.col = 1
    else
        self.col = self.col + 1
    end
    return char
end

function Lexer:isEOF()
    return self.pos > #self.source
end

function Lexer:skipWhitespace()
    while not self:isEOF() and self:peek():match("^%s$") do
        self:consume()
    end
end

function Lexer:skipComment()
    if self:peek() == '-' and self:peek(1) == '-' then
        self:consume() -- -
        self:consume() -- -
        
        -- Multi-line comment [[ ]]
        if self:peek() == '[' and self:peek(1) == '[' then
            self:consume() -- [
            self:consume() -- [
            while not (self:peek() == ']' and self:peek(1) == ']') and not self:isEOF() do
                self:consume()
            end
            if self:peek() == ']' then
                self:consume()
                self:consume()
            end
        else
            -- Single line comment
            while self:peek() ~= '\n' and not self:isEOF() do
                self:consume()
            end
        end
        return true
    end
    return false
end

function Lexer:readString()
    local quote = self:consume() -- " or '
    local str = ""
    
    while self:peek() ~= quote and not self:isEOF() do
        if self:peek() == '\\' then
            self:consume()
            local escape = self:consume()
            if escape == 'n' then str = str .. '\n'
            elseif escape == 't' then str = str .. '\t'
            elseif escape == 'r' then str = str .. '\r'
            elseif escape == '\\' then str = str .. '\\'
            elseif escape == quote then str = str .. quote
            else str = str .. escape end
        else
            str = str .. self:consume()
        end
    end
    
    if self:peek() == quote then
        self:consume()
    end
    
    return {
        type = "String",
        value = str,
        line = self.line,
        col = self.col
    }
end

function Lexer:readNumber()
    local num = ""
    local hasDecimal = false
    
    while not self:isEOF() and (self:peek():match("^[0-9]$") or self:peek() == '.') do
        if self:peek() == '.' then
            if hasDecimal then break end
            hasDecimal = true
        end
        num = num .. self:consume()
    end
    
    return {
        type = "Number",
        value = tonumber(num),
        line = self.line,
        col = self.col
    }
end

function Lexer:readIdentifier()
    local ident = ""
    
    while not self:isEOF() and self:peek():match("^[a-zA-Z0-9_]$") do
        ident = ident .. self:consume()
    end
    
    -- Lua keywords
    local keywords = {
        "and", "break", "do", "else", "elseif", "end", "false",
        "for", "function", "if", "in", "local", "nil", "not",
        "or", "repeat", "return", "then", "true", "until", "while"
    }
    
    for _, keyword in ipairs(keywords) do
        if ident == keyword then
            return {
                type = "Keyword",
                value = ident,
                line = self.line,
                col = self.col
            }
        end
    end
    
    return {
        type = "Identifier",
        value = ident,
        line = self.line,
        col = self.col
    }
end

function Lexer:nextToken()
    self:skipWhitespace()
    
    while self:skipComment() do
        self:skipWhitespace()
    end
    
    if self:isEOF() then
        return {type = "EOF", line = self.line, col = self.col}
    end
    
    local char = self:peek()
    
    -- Strings
    if char == '"' or char == "'" then
        return self:readString()
    end
    
    -- Numbers
    if char:match("^[0-9]$") then
        return self:readNumber()
    end
    
    -- Identifiers and Keywords
    if char:match("^[a-zA-Z_]$") then
        return self:readIdentifier()
    end
    
    -- Two-character operators
    local twoChar = self:peek() .. self:peek(1)
    local twoCharOps = {
        "==", "~=", "<=", ">=", "..", "[[", "]]", "::"
    }
    
    for _, op in ipairs(twoCharOps) do
        if twoChar == op then
            self:consume()
            self:consume()
            return {
                type = "Symbol",
                value = twoChar,
                line = self.line,
                col = self.col
            }
        end
    end
    
    -- Single-character symbols
    if char:match("^[%+%-%*/%%^#<>=%(%)%{%}%[%];:,.]$") then
        self:consume()
        return {
            type = "Symbol",
            value = char,
            line = self.line,
            col = self.col
        }
    end
    
    -- Unknown character
    local unknown = self:consume()
    return {
        type = "Unknown",
        value = unknown,
        line = self.line,
        col = self.col
    }
end

function Lexer:tokenize()
    local tokens = {}
    
    while not self:isEOF() do
        local token = self:nextToken()
        table.insert(tokens, token)
        if token.type == "EOF" then break end
    end
    
    return tokens
end

return Lexer
