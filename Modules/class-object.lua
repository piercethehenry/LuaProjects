--[[ 
            ##########################################################################################################################
                                    Basic implementation for classes and objects in LUA(ANY)(ANY)     
            ##########################################################################################################################                                    
]]--#endregion

local Objects = {
    ObjectStorage = {}, -- table for storing all objects
    ClassStorage = {}, -- table for storing all classes
    ClassGraveyard = {} -- table for storing classes that have been removed from use
}
Objects.__index = Objects -- sets the index of the Objects table to Objects, allowing for ObjectStorage to be accessed by Objects.ObjectStorage

local Assert, Type, Error = assert, type, error -- sets Assert to assert, Type to type, and Error to error
local DefaultProperties = { -- sets DefaultProperties to a table containing the default values for class and read_only
    ['class'] = '_default',
    ['read_only'] = {},
}

--[[ 
    Helps the Object.new function verify inputted properties
    @param Properties (table): table of properties for the object
    @returns Properties (table): verified and updated properties table
]]

function Objects.VerifyProperties(Properties)

    Assert(Type(Properties) == 'table', 'Properties must be a table')


    if not Properties then 
        return DefaultProperties
    else
        for Index, Value in pairs(DefaultProperties) do
            if not Properties[Index] then 
                Properties[Index] = Value
            end 
        end
    end 

    return Properties
end 

--[[
    Helps the Object.new function update the class objects table with a new object.
    @param ObjectIdentifier (string): unique identifier for the object
    @param Object (table): object to be added to the class objects table
    @param ClassIdentifier (string): unique identifier for the class that the object belongs to
]]

function Objects.UpdateClassObjects(ObjectIdentifier, Object, ClassIdentifier)
    Assert(Type(ObjectIdentifier) == 'string', 'ObjectIdentifier must be a string!')
    Assert(Type(ClassIdentifier) == 'string', 'ClassIdentifier must be a string!')
    Assert(Type(Object) == 'table', 'Object must be a table!')
    Assert(Objects.ClassStorage[ClassIdentifier], 'Class does not exist!')

    Objects.ClassStorage[ClassIdentifier].Objects[ObjectIdentifier] = Object
end 

--[[
    Helps the Object.new function verify the integrity of the class
    @param Identifier (string): unique identifier for the class
    @returns (boolean): returns if the class is private
]]
function Objects.VerifyClassIntegrity(Identifier) -- Verifies the integrity of the class by checking if the class is private
    Assert(Type(Identifier) == 'string', 'Identifier must be a string!') -- Asserts that the identifier is a string

    return Objects.ClassStorage[Identifier].IsPrivate -- Returns if the class is private
end 

--[[
    Creates a new Object which must have a class and properties
    @param Identifier (string): unique identifier for the object
    @param Properties (table): list of properties for the object
    @param ParentClass (table) (optional): parent class for the object

    @internal
        @param Object (table): table containing all the functions and properties for the object
        @
]]
function Objects.new(Identifier, Properties, ParentClass)

     Assert(Type(Identifier) == 'string', 'Identifier must be a string')
     Assert(Type(Properties) == 'table', 'Properties must be a table')

     -- Check if the parent class exists, and if it does then change the classes class proprety to the parent class identifier

     if ParentClass then 
        Properties.class = ParentClass.Identifier
     end 

     -- Check if the class is private

     if Objects.VerifyClassIntegrity(Properties.class) then 
        return Error('Class cannot be accessed!')
     end 

    -- Create the object

     local Object = {
        Identifier = Identifier,
        Properties = Objects.VerifyProperties(Properties),
        Class = Properties.class ~= nil and Properties.class or Objects.VerifyProperties(Properties).class,
        ParentClass = ParentClass or nil,
        IsInitialized = false,
        ChangeConnections = {}
     }

     --[[
        @function Object:_init
            @description: Initializes the object, setting IsInitialized to true and adding the object to the ObjectStorage table
            @internal
                @param self (table): the object
     ]]

     function Object:_init()
        Assert(self.IsInitialized == false, 'Object is already initialized!')
        self.IsInitialized = true 

        Objects.ObjectStorage[self.Identifier] = self
     end 

     --[[
        @function Object:force_property
            @description: forces the object to change its value without having to use Object:create_property
            @param Index (string): the index of the property
            @param Value (any): the new value of the property
            @internal
                @param self (table): the object
     ]]
    
     function Object:force_property(Index, Value )
        Assert(Index ~= 'read_only', 'read_only may not be modified or accessed!')
        Assert(Type(Index) == 'string', 'Index must be a string')

        self.Properties[Index] = Value
     end

     --[[
        @function inherit
            @description: Inherits properties from other objects
            @param Identifier_ (string): the identifier for the object
            @param Exclude (table): list of values to exclude for inheritance
            @internal
                @param ToInherit (table): properties to inherit
     ]]
   
     function Object:inhert(Identifier_, Exclude)
        Assert(Type(Identifier_) == 'string', 'Identifier must be a string')
        Assert(Objects.ObjectStorage[Identifier_], 'Object does not exist!')
        Assert(Identifier_ == self.Identifier, 'Object can not inherit itself!')

        if not Exclude then 
            Exclude = {}
        end

        local ToInherit = Objects.ObjectStorage[Identifier_]
        
        for Index, _ in next, Exclude do 
            if ToInherit[Index] then 
                ToInherit[Index] = nil
            end 
        end

        for Index, Value in next, ToInherit do 
            if not self.Properties[Index] and Index ~= 'read_only' then 
                self.Properties[Index] = Value
            end 
        end 
     end 

     
     --[[
        @function remove_property
            @description: removes the property from the property table if it exists
            @param Index (string): the index for the value you want to remove
     ]]

     function Object:remove_property(Index)
        Assert(Index ~= 'read_only', 'read_only may not be modified or accessed!')
        Assert(Type(Index) == 'string', 'Index must be a string')
        Assert(self.Properties[Index], 'Property does not exist!')

        if self.ChangeConnections[Index] ~= nil then 
            self.ChangeConnections[Index] = nil
        end 

        self.Properties[Index] = nil
     end 

     --[[
        @function create_property
            @description: creates a new property if it doesnt already exist
            @param Index (string): the identifier for the value
            @param Value (any): value for the new index
     ]]

     function Object:create_property(Index, Value)
        Assert(Index ~= 'read_only', 'read_only may not be modified or accessed!')
        Assert(Type(Index) == 'string', 'Index must be a string')
        Assert(self.Properties[Index] == nil, ('Property with Index %s already exists! Please use Object:change_property(%s, %s)'):format(Index, Index, Value))

        self.Properties[Index] = Value 
     end 

     --[[
        @function change_property
            @description: changes a property if it already exists in the Properties table
            @param Index (string): the identifier for the value
            @param Value (any): the new value for the index
     ]]

     function Object:change_property(Index, Value)
        Assert(Index ~= 'read_only', 'read_only may not be modified or accessed!')
        Assert(Type(Index) == 'string', 'Index must be a string!')
        Assert(self.Properties[Index], ('Property does not exist! Please use Object:create_property(%s, %s)'):format(Index, Index, Value))

        if self.ChangeConnections[Index] ~= nil then 
            self.ChangeConnections[Index](Value)
        end 

        self.Properties[Index] = Value
     end 

     --[[
        @function is_property
            @description: returns whether a property with the inputted index exists
            @param Index (string): the index for the property
            @returns: boolean
     ]]

     function Object:is_property(Index)
        return self.Properties[Index] ~= nil 
     end 

     --[[
        @event_function on_change 
            @description: an event_function that will bind the inputted function to when the property with the inputted index is changed
            @param Index (string): the identifier for the value you want to connect to when its value gets changed
            @param Function (function): function for when the value is changed
                @returns: new VALUE
     ]]

     function Object:on_change(Index, Function)
        Assert(Index ~= 'read_only', 'read_only may not be modified or accessed!')
        Assert(Type(Index) == 'string', 'Index must be a string!')
        Assert(Type(Function) == 'function', 'Function must be a function!')

        self.ChangeConnections[Index] = Function
     end 

     --[[
        @function get_read_only
            @description: get the value of a read only index
            @param Index (string): the identifier for the value inside the read_only table
            @returns: any
     ]]

    function Object:get_read_only(Index)
        Assert(self.Properties.read_only[Index], 'Property does not exist in read_only!')

        return self.Properties.read_only[Index]
    end 

    --[[
        @function is_read_only
            @description: will return whether the inputted index exists in the read_only table
            @param Index (string): the identifier for the value
            @returns: boolean
     ]]

    function Object:is_read_only(Index)
        return self.Properties.read_only[Index] ~= nil 
    end
    --[[
        @function fetch_property
            @description: returns the value of the given index assuming the index is on a public scope
            @param Index (string): the identifier for the value
            @returns: any
     ]]

    function Object:fetch_property(Index)
        Assert(self.Properties[Index], 'Property does not exist!')

        return self.Properties[Index]
    end 
    
    --[[
        @function remove
            @description: removes the object but stores an object in the Objects.ObjectStorage table for recovery
     ]]

    function Object:remove()
        Objects.ObjectStorage[self.Identifier] = self 
        
        if self.Properties.on_destroy ~= nil then 
            self.Properties.on_destroy()
        end 

        if self.ParentClass then 
            self.ParentClass:update_default(self.Identifier)
        end 

        self = {}
        setmetatable(self, {})
    end 

   --[[
        @function destroy
            @description: the same as remove but cooler name
     ]]

    function Object:destroy()
        self:remove()
    end 

    --[[
        @function make_public
            @description: makes a read_only value accessible to the public scope
            @param Index (string): the identifier for the value
     ]]

    function Object:make_public(Index)
        Assert(Index ~= 'read_only', 'read_only may not be modified or accessed!')
        Assert(self.Properties.read_only[Index], 'Index is already on a public scope or does not exist!')

        local Value = self.Properties.read_only[Index]

        self.Properties[Index] = Value
        self.Properties.read_only[Index] = nil 
    end 

    --[[
        @function get_identifier
            @description: returns the objects identifier
            @returns: string
     ]]

    function Object:get_identifier()
        return self.Identifier
    end

    --[[
        @function make_read_only
            @description: makes the index read only if the property already exists
            @param Index (string): the identifier for the value
     ]]

    function Object:make_read_only(Index)
        Assert(Index ~= 'read_only', 'read_only may not be modified or accessed!')
        Assert(self.Properties.read_only[Index], 'Index is already on a public scope or does not exist!')

        local Value = self.Properties[Index]

        self.Properties.read_only[Index] = Value
        self.Properties[Index] = nil 
    end 

    --[[
        @function inherit
            @description: inherits the given objects properties
            @param Object (table) (object): the object
     ]]

    function Object:inherit(Object_)
        Assert(Type(Object_) == 'table', 'Object must be a table!')

        for Index, Value in next, Object_.Properties do 
            if not self.Properties[Index] and Index ~= 'read_only' and Index ~= 'on_create' and Index ~= 'on_destroy' then 
                self.Properties[Index] = Value
            end 
        end
    end 

    --[[
        @function clone
            @description: clones the object
            @returns: new Object
     ]]
    function Object:clone()
        local NewObject = Objects.new(self.Identifier, self.Properties)

        return NewObject
    end 

    --[[
        @function inherit_class
            @description: inherits the class's properties with the given index
            @param Index (string): the identifier for the value
            @returns: any
     ]]

     function Object:inherit_class(Class)
        Assert(Type(Class) == 'string', 'Class must be a string')
        Assert(Object.ClassStorage[Identifier], 'Class does not exist!')

        local ToInherit = Objects.ClassStorage[Identifier]

        for Index, Value in next, ToInherit do 
            if not self.Properties[Index] and Index ~= 'read_only' and Index ~= 'on_destroy' and Index ~= 'on_create' then 
                self.Properties[Index] = Value 
            end 
        end 
     end 

     if Object.on_create and Type(Object.on_create) == 'function' then 
        Object.on_create()
     end

     Object:_init()
     Objects.UpdateClassObjects(Identifier, Object, Object.Class)

     setmetatable(Object, {
        __index = function(self, Index)
            if Index ~= 'read_only' and self.Properties[Index] ~= nil then 
                return self.Properties[Index]
            elseif Index == 'read_only' then 
                return Error('Attempt to modify read_only!')
            else
                return Error(('Property %s does not exist!'):format(Index))
            end
        end,

        __newindex = function(_, Index)
            if Index == 'read_only' then 
                return Error('Attempt to modify read_only!')
            end 
        end 
     })

     -- @info check if the ParentClass exists and inherit its properties

     if ParentClass and Type(ParentClass) == 'table' then 
        for Index, Value in next, ParentClass.Properties do 
            if not Object.Properties[Index] and Index  ~= 'IsPrivate' and Index ~= 'read_only' then 
                Object.Properties[Index] = Value
            end 
        end 

        Object.class = ParentClass.Identifier
     end  


     return Object
end 

--[[
        @function fetch_object
            @description: returns the object with the given Identifier
            @param Identifier (string): the identifier for the object
            @returns: table
]]

function Objects.fetch_object(Identifier)
    Assert(Objects.ObjectStorage[Identifier], 'Object does not exist in object storage!')

    return Objects.ObjectStorage[Identifier]
end 

function Objects.RecoverClass(Identifier)
    Assert(Type(Identifier) == 'string', 'Identifier must be a string')

end 

--[[
        @function class
            @description: creates a new class for objects to use 
            @param Identifier (string): the identifier for the class
            @param Properties (table): the property table for the class
            @returns: table
]]

function Objects.class(Identifier, Properties)
    Assert(Type(Identifier) == 'string', 'Identifier must be a string')
    Assert(Objects.ClassStorage[Identifier] == nil, 'Class already exists!')

    -- @info create the class

    local Class = {
        Identifier = Identifier,
        Properties = Objects.VerifyProperties(Properties),
        Objects = {},
        IsPrivate = Properties.IsPrivate ~= nil and Properties.IsPrivate or false,
        DefaultMethods = {}
    }

    Objects.ClassStorage[Identifier] = Class

    --[[
        @function verify_objects
            @description: go through the Objects.ObjectStorage table and check if the object has the same class as the created class and add it to the objects list
     ]]

    function Class:verify_objects()
        for Index, Value in next, Objects.ObjectStorage do 
            if Value.Class == self.Identifier then 
                self.Objects[Index] = Value
            end 
        end
    end 

    --[[
        @function purge_objects
            @description: destroys all the objects in the class
     ]]

    function Class:purge_objects()
        for _, Value in next, self.Objects do 
            Value:destroy()
        end
    end 

    --[[
        @function make_private
            @description: make it so other objects cant use the class
     ]]

    function Class:make_private()
        self.IsPrivate = true 
    end 

    --[[
        @function make_public
            @description: make it so other objects can use the class
     ]]

    function Class:make_public()
        self.IsPrivate = false
    end 

    --[[
        @function make_default_method
            @description: create a new default method for the class, used by initilizing an object
            @param Index (string): the identifier for the method
     ]]

    function Class:make_default_method(Index)
        Assert(Index, 'Index cannot be nil!')

        if Type(Index) == 'table' then  
            self.DefaultMethods[Index:get_identifier()] = Index 
        elseif Type(Index) == 'string' then 
            self.DefaultMethods[Index] = self.Objects[Index]
        end   
    end 

    --[[
        @function fetch_property
            @description: remove a default method with the given index
     ]]

    function Class:update_default(Index)
        Assert(Type(Index) == 'string', 'Index must be a string!')
        
        if self.DefaultMethods[Index] then 
            self.DefaultMethods[Index] = nil
        end 
    end 

    --[[
        @function fetch_property
            @description: use a default method that was set
            @param Index (string): the identifier for the method
     ]]

    function Class:port_method(Index)
        Assert(self.DefaultMethods[Index], 'Index is not a default method!')
        Assert(self.Objects[Index], 'Object no longer exists!')
        
        return self.Objects[Index]:clone()
    end 

    --[[
        @function fetch_property
            @description: returns whether the class can be accessed
            @returns: boolean
     ]]

    function Class:can_access()
        return self.IsPrivate
    end 

    --[[
        @function new
            @description: create an object with the classes properties
            @returns: new Object
     ]]

    function Class.new()
        return Objects.new(Class.Identifier, Class.Properties, Class)
    end 

    --[[
        @function remove
            @description: removes the class and all the objects associated with it
     ]]

    function Class:remove()
        for _, Value in next, self.Objects do 
            Value:destroy()
        end

        Objects.ClassGraveyard[self.Identifier] = self

        if self.Properties.on_destroy ~= nil then 
            self.Properties.on_destroy()
        end 

        self = {}
        setmetatable(self, {})
    end 

    --[[
        @function object_count
            @description: returns the value of amount of objects in the table
            @returns: number
     ]]

    function Class:object_count()
        return #self.Objects
    end 

    --[[
        @function return_object
            @description: returns the object with the given Identifier
            @param Identifier (string): name for the object
            @returns: Object
     ]]
     
    function Class:return_object(Identifier_)
        Assert(self.Objects[Identifier_], 'Object does not exist in object storage!')

        return self.Objects[Identifier_]
    end 

    --[[
        @function update_all_objects
            @description: updates all the objects properties with the given Properties table
            @param Properties (table): list of new properties
     ]]

    function Class:update_all_objects(Properties_)
        for Index, Value in next, Properties_ do 
            for _ , Object in next, self.Objects do 
                    Object:force_property(Index, Value)
                end 
            end
        end 

    
    if Properties.on_init ~= nil then 
        Properties.on_init()
    end 

    setmetatable(Class, {
        __index = Class
    })

    Class:verify_objects()
    return Class 
end 

return Objects
