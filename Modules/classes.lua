local Classes = {
    ClassDictonary = {},
    DefinedIdentifiers = {},
    ClassGarbage = {}
}

local RequiredMethods = {'public', 'private'}
local Assert = assert 
local Type = type

function Classes._construct(Constructor)
    for Index, Value in next, Constructor do

        
        if Type(Value) == 'table' and Index ~= 'public' and Index ~= 'private' and Index ~= 'static' then 
            if Value._canaccess then 
                Constructor.public[Index] = Value 
            else
                Constructor.private[Index] = Value
            end 
        end 
    end 

    return Constructor
end 

function Classes._validate(Identifier, Properties)
    if not Identifier then 
        Identifier = '_newclass'
    end 

    if not Properties then 
        Properties = {
            public = {},
            private = {}
        }
    else
        for _, Method in next, RequiredMethods do 
            if  not Properties[Method] then 
                Properties[Method] = {}
            end 
        end     
    end 

    Classes._construct(Properties)

    return Identifier, Properties
end 


function Classes._recover(Identifier)

    Assert(Identifier or type(Identifier) == 'string', 'Identifier must  be a string!')

    if Classes.ClassGarbage[Identifier] then 
       return Classes.ClassGarbage[Identifier]
    end

    return 'Class does not exist in garbage collection'
end 

function Classes.create(Identifier, ConstructorTable, ParentClass)

    Assert(Type(Identifier) == 'string', 'Identifier must be a string!')
    Assert(Type(ConstructorTable) == 'table', 'Constructor must be a table!')

    if Classes.DefinedIdentifiers[Identifier] then 
        return error(('Identifier %s already has a class!'):format(Identifier))
    end 

    local ValidatedIdentifier, ValidatedProperties = Classes._validate(Identifier, ConstructorTable)
    
    local Class = {
        Identifier = ValidatedIdentifier,
        Constructor = ValidatedProperties,
    }

    if ParentClass then  
        Class.ParentClass = ParentClass 
    end 

    function Class:_contain(Index, Value)
        self.Constructor.private[Index] = Value 
    end 

    function Class:_free(Index, Value)
        Assert(Index, 'Index cannot be nil!')
        Assert(Value, 'Value cannot be nil!')

        if self.Constructor.private[Index] then 
            self.Constructor.private[Index] = nil 
        end 

        self.Constructor.public[Index] = Value 
    end 

    function Class:_remove_method(Index)
        Assert(Index, 'Index cannot be nil!')

        if self.Constructor.public[Index] then 
            self.Constructor.public[Index] = nil
        end 
    end 

    function Class:_append(TableName, Index, Value)

        Assert(TableName, 'Table name must be a string!')
        Assert(self.Constructor.public[TableName], 'Table does not exist in the public scope!')
        
        self.Constructor.public[TableName][Index] = Value
    end 

    function Class:respect_method(Index)
        Assert(Index, 'Index cannot be nil!')
  
        local Method = self.Constructor.public[Index]

        if Method then 
            self.Constructor.private[Index] = Method
            self.Constructor.public[Index] = nil
        end 
    end 

    function Class:remove()
        Classes.ClassGarbage[self.Identifier] = self
        self = {}
        setmetatable(self, {})
    end 

    function Class:dump_public()
        local String = ''
        for Index, Value in next, self.Constructor.public do 
            String = String .. ('%s:%s,'):format(Index, Value)
        end 

        return String
    end 

    setmetatable(Class, {
        __index = function(self, Index)

            if self.Constructor.private[Index] ~= nil then 
                return ('Identifier %s is in a private scope!\npublic methods: %s'):format(Index, self:dump_public())
            end 

            if self.Constructor.public[Index] ~= nil then 
                return self.Constructor.public[Index]
            end 

            return ('Identifier %s does not exist.'):format(Index)
        end 
    })

    Classes.DefinedIdentifiers[Identifier] = ConstructorTable
    Classes.ClassDictonary[Class] = Class 
    
    if ConstructorTable.on_create and Type(ConstructorTable.on_create) == 'function' then 
        ConstructorTable.on_create(Class.Constructor.public)
    end 

    return Class
end 

return Classes
