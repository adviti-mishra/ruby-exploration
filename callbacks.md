Mongoid reference for Document Callbacks

# Ordering and what they do
## Order in which they will get called during the respective operations: 
### Creating an object 
validate -> save -> create

1. before_validation 
2. after_validation
3. before_save
4. around_save
5. before_create
6. around_create
7. after_create
8. after_save

### Updating an object 
validate -> save -> update

1. before_validation
2. after_validation
3. before_save
4. around_save
5. before_update
6. around_update
7. after_update
8. after_save

### Destroying an Object 

destroy 

1. before_destroy
2. around_destroy
3. after_destroy

# Callback functions

## before_validation 
Actions that trigger it: :create, :update<br/>
Called: before the model validation takes place. 

## after_validation
Actions that trigger it: :create, :update<br/>
Called: after the model validation takes place

## before_save 
Actions that trigger it: :create, :update<br/>
Called: before the object is persisted to the database 

## around_save 
Actions that trigger it: :create, :update<br/>
Called: around the saving the object and inside the before_save and after_save actions<br/>
The yield in the around_save method yields to the code performing the action(save) 

## before_create
Actions that trigger it: :create<br/>
Same as before_save, but only triggered by the create action  

## around_create 
Actions that trigger it: :create <br/>
Same as around_save, but only triggered by the create action

## after_create 
Actions that trigger it: :create<br/>
Same as after_save, but only triggered by the create action 

## after_save
Actions that trigger it: :create, :update <br/>
Called: after the object has been saved to the database 

## before_update 
Actions that trigger it: :update<br/>
Same as before_save, but only triggered by the update action  

## around_update 
Actions that trigger it: :update<br/>
Same as around_save, but only triggered by the update action  

## after_update 
Actions that trigger it: :update<br/>
Same as after_save, but only triggered by the update action  

## before_destroy 
Actions that trigger it: :destroy

## around_destroy 
Actions that trigger it: :destroy

## after_destroy
Actions that trigger it: :destroy

## after_initialize 

## after_build

## after_find


## after_upsert 
## around_upsert
## before_upsert  



















































