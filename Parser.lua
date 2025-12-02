--[[
    Parser.lua
    Parses tokens into an Abstract Syntax Tree (AST)
]]--

local Parser = {}
Parser.__index = Parser

function Parser.new(tokens)
    local self = setmetatable({}, Parser)
    self.tokens = tokens
    self.pos = 1
    return self
end

function Parser:peek(offset)
    offset = offset or 0
    return self.tokens[self.pos + offset] or {type = "EOF"}
end

function Parser:consume()
    local token = self:peek()
    self.pos = self.pos + 1
    return token
end

function Parser:expect(tokenType, value)
    local token = self:consume()
    
    if token.type ~= tokenType then
        error(string.format("Line %d: Expected %s, got %s", 
            token.line or 0, tokenType, token.type))
    end
    
    if value and token.value ~= value then
        error(string.format("Line %d: Expected '%s', got '%s'", 
            token.line or 0, value, token.value))
    end
    
    return token
end

function Parser:isEOF()
    return self:peek().type == "EOF"
end

-- Parse primary expressions (literals, variables, parentheses)
function Parser:parsePrimary()
    local token = self:peek()
    
    if token.type == "Number" then
        self:consume()
        return {
            type = "NumberLiteral",
            value = token.value
        }
    end
    
    if token.type == "String" then
        self:consume()
        return {
            type = "StringLiteral",
            value = token.value
        }
    end
    
    if token.type == "Keyword" then
        if token.value == "true" or token.value == "false" then
            self:consume()
            return {
                type = "BooleanLiteral",
                value = token.value == "true"
            }
        end
        
        if token.value == "nil" then
            self:consume()
            return {
                type = "NilLiteral"
            }
        end
    end
    
    if token.type == "Identifier" then
        local name = self:consume().value
        
        -- Function call
        if self:peek().value == "(" then
            self:consume() -- (
            local args = {}
            
            while self:peek().value ~= ")" and not self:isEOF() do
                table.insert(args, self:parseExpression())
                
                if self:peek().value == "," then
                    self:consume()
                end
            end
            
            self:expect("Symbol", ")")
            
            return {
                type = "CallExpression",
                callee = name,
                arguments = args
            }
        end
        
        return {
            type = "Identifier",
            name = name
        }
    end
    
    if token.value == "(" then
        self:consume()
        local expr = self:parseExpression()
        self:expect("Symbol", ")")
        return expr
    end
    
    error(string.format("Line %d: Unexpected token %s", token.line or 0, token.type))
end

-- Parse binary expressions (operators)
function Parser:parseExpression()
    local left = self:parsePrimary()
    
    local token = self:peek()
    if token.type == "Symbol" and token.value == ".." then
        self:consume()
        local right = self:parseExpression()
        return {
            type = "BinaryExpression",
            operator = "..",
            left = left,
            right = right
        }
    end
    
    return left
end

-- Parse statements
function Parser:parseStatement()
    local token = self:peek()
    
    -- Local variable declaration
    if token.type == "Keyword" and token.value == "local" then
        self:consume()
        
        -- Local function
        if self:peek().type == "Keyword" and self:peek().value == "function" then
            self:consume()
            local name = self:expect("Identifier").value
            
            self:expect("Symbol", "(")
            local params = {}
            
            while self:peek().value ~= ")" and not self:isEOF() do
                table.insert(params, self:expect("Identifier").value)
                
                if self:peek().value == "," then
                    self:consume()
                end
            end
            
            self:expect("Symbol", ")")
            
            local body = {}
            while not (self:peek().type == "Keyword" and self:peek().value == "end") and not self:isEOF() do
                table.insert(body, self:parseStatement())
            end
            
            self:expect("Keyword", "end")
            
            return {
                type = "LocalFunction",
                name = name,
                parameters = params,
                body = body
            }
        end
        
        -- Local variables
        local names = {}
        table.insert(names, self:expect("Identifier").value)
        
        while self:peek().value == "," do
            self:consume()
            table.insert(names, self:expect("Identifier").value)
        end
        
        local values = {}
        if self:peek().value == "=" then
            self:consume()
            
            table.insert(values, self:parseExpression())
            
            while self:peek().value == "," do
                self:consume()
                table.insert(values, self:parseExpression())
            end
        end
        
        return {
            type = "LocalDeclaration",
            names = names,
            values = values
        }
    end
    
    -- Return statement
    if token.type == "Keyword" and token.value == "return" then
        self:consume()
        
        local values = {}
        if self:peek().type ~= "Keyword" and not self:isEOF() then
            table.insert(values, self:parseExpression())
            
            while self:peek().value == "," do
                self:consume()
                table.insert(values, self:parseExpression())
            end
        end
        
        return {
            type = "ReturnStatement",
            values = values
        }
    end
    
    -- Expression statement (assignments, function calls)
    if token.type == "Identifier" then
        local expr = self:parseExpression()
        return expr
    end
    
    -- Unknown statement
    return {type = "Unknown"}
end

-- Parse entire program
function Parser:parse()
    local body = {}
    
    while not self:isEOF() do
        local stmt = self:parseStatement()
        if stmt.type ~= "Unknown" then
            table.insert(body, stmt)
        end
    end
    
    return {
        type = "Program",
        body = body
    }
end

return Parser
