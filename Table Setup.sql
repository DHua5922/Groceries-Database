Use groceries

--------------
--- Tables ---
--------------

--- User ---
CREATE TABLE [user] (
	[id] int IDENTITY(1,1) NOT NULL,
	[username] nvarchar(max) DEFAULT '',
	[email] nvarchar(max) DEFAULT '',
	[password] nvarchar(max),
	PRIMARY KEY (id)
)
GO

--- List ---
CREATE SCHEMA [list_schema]
GO
CREATE TABLE [list] (
	[id] int IDENTITY(1,1) NOT NULL,
	[name] nvarchar(max) DEFAULT '',
	[sequence] int NOT NULL,
	[userId] int,
	PRIMARY KEY (id),
	FOREIGN KEY (userId) REFERENCES [user](id)
)
CREATE SEQUENCE [list_schema].[sequence] START WITH 1 INCREMENT BY 1
GO

--- Item ---
CREATE SCHEMA [item_schema]
GO
CREATE TABLE [item] (
	[id] int IDENTITY(1,1) NOT NULL,
	[name] nvarchar(max) DEFAULT '',
	[price] float DEFAULT 0,
	[sequence] int NOT NULL,
	[listId] int,
	PRIMARY KEY (id),
	FOREIGN KEY (listId) REFERENCES [list](id)
)
CREATE SEQUENCE [item_schema].[sequence] START WITH 1 INCREMENT BY 1
GO

----------------
--- Triggers ---
----------------

-- Delete triggers for tables executes when deleting row(s) for those tables.
-- Note: [deleted] is built-in table. Whenever a row is being deleted, that row is in deleted table.
-- Imporant: 
	-- Referential integrity is enforced in this database:
	-- new row(s) must be inserted into parent table first before inserting row(s) into child table.
	--		Example: list has a foreign key of userId that refers to user by user's id. Inserting a list with a user id that doesn't exist in user table violates the referential integrity constraint, so that list will not be inserted. User that the list refers to must be inserted first before that list can be inserted.
	-- row(s) must be deleted from child table first before deleting row(s) from parent table.
	--		Example: item has a foreign key of listId that refers to list by list's id. Deleting a list that still has items that references that list violates the referential integrity constraint, so that list will not be deleted. Items that refer to that list must be deleted first before that list can be deleted.
CREATE OR ALTER TRIGGER onDeleteUserTrigger
	ON [user] INSTEAD OF DELETE
	AS
		BEGIN
			-- Because list refers to user, list will be deleted first before deleting user. 
			-- But because of trigger that deletes item first before deleting list, deletion occurs in the order:
			--	1. Items that refer to that list will be deleted first
			--	2. List will be deleted
			--	3. User that list refers to will be deleted.
			DELETE FROM [list] WHERE [userId] IN (SELECT [id] FROM [deleted])
			DELETE FROM [user] WHERE [id] IN (SELECT [id] FROM [deleted])
		END
GO

CREATE OR ALTER TRIGGER onDeleteListTrigger
	ON [list] INSTEAD OF DELETE
	AS
		BEGIN
			-- Because item refers to list, item will be deleted first before deleting list
			DELETE FROM [item] WHERE [listId] IN (SELECT [id] FROM [deleted])
			DELETE FROM [list] WHERE [id] IN (SELECT [id] FROM [deleted])
		END
GO

-------------------------
--- Stored Procedures ---
-------------------------

--- User ---
CREATE OR ALTER PROCEDURE getUser 
	-- Add the parameters for the stored procedure here
	@id int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF ISNULL(@id, 0) <> 0
		SELECT * FROM [user] WHERE [id] = @id;
	ELSE
		SELECT * FROM [user];
END
GO

CREATE OR ALTER PROCEDURE upsertUser 
	-- Add the parameters for the stored procedure here
	@id int,
	@username nvarchar(max),
	@email nvarchar(max),
	@password nvarchar(max),
	@statusCode int OUTPUT,
	@statusMessage TEXT OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @currentId int

	IF ISNULL(@id, 0) <> 0
		BEGIN
			UPDATE [user] 
			SET 
				[username] = @username, 
				[email] = @email, 
				[password] = @password 
			WHERE [id] = @id

			SET @statusCode = 1
			SET @statusMessage = 'Updated profile'
			SET @currentId = @id
		END
	ELSE
		BEGIN
			DECLARE @lastIdentityValue INT
			SET @lastIdentityValue = SCOPE_IDENTITY()

			INSERT INTO [user] 
				(
					[username], 
					[email], 
					[password]
				) 
			VALUES 
				(
					@username, 
					@email, 
					@password
				)

			SET @statusCode = 1
			SET @statusMessage = 'Account has been created'
			SET @currentId = SCOPE_IDENTITY()
		END

	SELECT * FROM [user] WHERE [id] = @currentId
END
GO

CREATE OR ALTER PROCEDURE deleteUser 
	-- Add the parameters for the stored procedure here
	@id int,
	@statusCode int OUTPUT,
	@statusMessage TEXT OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF ISNULL(@id, 0) <> 0
		BEGIN
			DELETE FROM [user] WHERE id = @id
			SET @statusCode = 1
			SET @statusMessage = 'Deleted account'
		END
	ELSE
		BEGIN
			SET @statusCode = 0
			SET @statusMessage = 'User does not exist'
		END
END
GO

--- List ---
CREATE OR ALTER PROCEDURE getList
	-- Add the parameters for the stored procedure here
	@id int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF ISNULL(@id, 0) <> 0
		SELECT * FROM [list] WHERE [id] = @id;
	ELSE
		SELECT * FROM [list];
END
GO

CREATE OR ALTER PROCEDURE upsertList 
	-- Add the parameters for the stored procedure here
	@id int,
	@name nvarchar(max),
	@sequence int,
	@userId int,
	@statusCode int OUTPUT,
	@statusMessage TEXT OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @currentId int

	IF ISNULL(@id, 0) <> 0
		BEGIN
			UPDATE [list] 
			SET 
				[name] = @name, 
				[sequence] = @sequence, 
				[userId] = @userId 
			WHERE [id] = @id

			SET @statusCode = 1
			SET @statusMessage = 'Updated list'
			SET @currentId = @id
		END
	ELSE
		BEGIN
			DECLARE @lastIdentityValue INT
			SET @lastIdentityValue = SCOPE_IDENTITY()

			INSERT INTO [list] 
				(
					[name],
					[sequence],
					[userId]
				) 
			VALUES 
				(
					@name, 
					NEXT VALUE FOR [list_schema].[sequence], 
					@userId
				)

			SET @statusCode = 1
			SET @statusMessage = 'Created list'
			SET @currentId = SCOPE_IDENTITY()
		END

	SELECT * FROM [list] WHERE [id] = @currentId
END
GO

CREATE OR ALTER PROCEDURE deleteList
	-- Add the parameters for the stored procedure here
	@id int,
	@statusCode int OUTPUT,
	@statusMessage TEXT OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF ISNULL(@id, 0) <> 0
		BEGIN
			DELETE FROM [list] WHERE id = @id
			SET @statusCode = 1
			SET @statusMessage = 'Deleted list'
		END
	ELSE
		BEGIN
			SET @statusCode = 0
			SET @statusMessage = 'List does not exist'
		END
END
GO

--- Item ---
CREATE OR ALTER PROCEDURE getItem
	-- Add the parameters for the stored procedure here
	@id int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF ISNULL(@id, 0) <> 0
		SELECT * FROM [item] WHERE [id] = @id;
	ELSE
		SELECT * FROM [item];
END
GO

CREATE OR ALTER PROCEDURE upsertItem 
	-- Add the parameters for the stored procedure here
	@id int,
	@name nvarchar(max),
	@price float,
	@sequence int,
	@listId int,
	@statusCode int OUTPUT,
	@statusMessage TEXT OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @currentId int

	IF ISNULL(@id, 0) <> 0
		BEGIN
			UPDATE [item] 
			SET 
				[name] = @name, 
				[price] = @price,
				[sequence] = @sequence, 
				[listId] = @listId
			WHERE [id] = @id

			SET @statusCode = 1
			SET @statusMessage = 'Updated item'
			SET @currentId = @id
		END
	ELSE
		BEGIN
			DECLARE @lastIdentityValue INT
			SET @lastIdentityValue = SCOPE_IDENTITY()

			INSERT INTO [item] 
				(
					[name],
					[price],
					[sequence],
					[listId]
				) 
			VALUES 
				(
					@name, 
					@price,
					NEXT VALUE FOR [item_schema].[sequence], 
					@listId
				)

			SET @statusCode = 1
			SET @statusMessage = 'Added item to list'
			SET @currentId = SCOPE_IDENTITY()
		END

	SELECT * FROM [item] WHERE [id] = @currentId
END
GO

CREATE OR ALTER PROCEDURE deleteItem
	-- Add the parameters for the stored procedure here
	@id int,
	@statusCode int OUTPUT,
	@statusMessage TEXT OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF ISNULL(@id, 0) <> 0
		BEGIN
			DELETE FROM [item] WHERE id = @id
			SET @statusCode = 1
			SET @statusMessage = 'Removed item from list'
		END
	ELSE
		BEGIN
			SET @statusCode = 0
			SET @statusMessage = 'Item does not exist'
		END
END
GO