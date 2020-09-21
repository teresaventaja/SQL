# Create database

CREATE DATABASE Drone_Store;

# Create tables

USE drone_store;
CREATE TABLE Customers (
CustomerID int not null auto_increment,
FirstName varchar (30),
LastName varchar (50),
Address varchar (100),
email varchar (40),
phone int (20),
PRIMARY KEY (CustomerID)
);
USE drone_store;
CREATE TABLE Suppliers (
SupplierID int not null auto_increment,
SupName varchar (100),
SupAddress varchar (100),
SupPointOfContact varchar (100),
SupPhone int (40),
PRIMARY KEY (SupplierID)
);
USE drone_store;
CREATE TABLE Stock (
StockID int not null auto_increment,
ItemTitle varchar (100),
CostPrice varchar (40),
StockLevel int,
SupplierID int,
PRIMARY KEY (StockID),
CONSTRAINT FK_SupplierStock foreign key (SupplierID)
REFERENCES Suppliers(SupplierID)
);
USE drone_store;
CREATE TABLE OrderItems (
BarCode varchar (200),
StockID varchar (200),
item varchar(100),
QuantitySold int (5),
SalePrice varchar (10),
VAT varchar (8),
OrderID int,
PRIMARY KEY (BarCode)
);
USE drone_store;
CREATE TABLE Orders (
OrderID int not null auto_increment,
CustomerID int,
OrdersDate date,
PurchaseMode varchar (10),
DeliveryAddress varchar (200),
DeliveryStatus varchar (100),
PRIMARY KEY (OrderID),
CONSTRAINT FK_CustomerOrder foreign key (CustomerID)
REFERENCES Customers(CustomerID)
);
USE drone_store;
CREATE TABLE Payments (
TransactionID int not null auto_increment,
CustomerID int,
OrderID int,
FinalPrice varchar (10),
CardNumber varchar (16),
PaymentStatus varchar(60),
PRIMARY KEY (TransactionID),
CONSTRAINT FK_WhoPays foreign key (CustomerID)
REFERENCES Customers(CustomerID),
CONSTRAINT FK_OrdertoPay foreign key (OrderID)
REFERENCES Orders(OrderID)
);
USE drone_store;
CREATE TABLE PaymentMethod (
CustomerID int,
CardType varchar(50),
CardName varchar(100),
CardNumber varchar (16),
CVV int(3),
PRIMARY KEY (CardNumber),
CONSTRAINT FK_CardOwnner foreign key (CustomerID)
REFERENCES Customers(CustomerID)
);
USE drone_store;
CREATE TABLE OrderReturn (
ReturnID int not null auto_increment,
TransactionID int,
RefundAmount varchar (10),
CardNumber varchar(16),
RefundStatus varchar (50),
ReturnDeliveryStatus varchar (50),
PRIMARY KEY (ReturnID),
CONSTRAINT FK_TransactionRefund foreign key (TransactionID)
REFERENCES payments(transactionID),
CONSTRAINT FK_RefundCard foreign key (CardNumber)
REFERENCES paymentmethod(CardNumber)
);

# Creating DataMart

Create Database DataMart;

# Creating view for Exercise 1

Use drone_store;
Create VIEW Exercise1 AS
SELECT Orders.OrdersDate, payments.TransactionID, orders.OrderID, payments.FinalPrice, payments.CardNumber, payments.PaymentStatus
FROM Orders
INNER JOIN payments
ON orders.OrderID = payments.OrderID
WHERE orders.OrdersDate 
HAVING OrdersDate BETWEEN '2019-08-12' AND '2019-08-18';

# Creating a table in the DataMart with the view
# Inserting the data created in the view (drone_store) to my DataMart
USE DataMart;
Create Table DataMart.Exercise1_Data SELECT * FROM drone_store.exercise1; 

# Resolution to Exercise 1
USE DataMart;
SELECT * FROM exercise1_data;

# Creating audit table for exercise 2

USE drone_store;
create table stock_audit(
stockID int,
itemtitle varchar(100),
costprice varchar(40),
stocklevel int,
supplierID int
);

# Creating trigger for auditing all changes (exercise 2)

DELIMITER $$
CREATE TRIGGER before_update_stock
    BEFORE UPDATE ON stock
    FOR EACH ROW BEGIN
    INSERT INTO stock_audit
    SET
	StockID = OLD.stockID,
	itemtitle = OLD.itemtitle,
	costprice = old.costprice,
	stocklevel = old.stocklevel,
	supplierID = old.supplierID;
END$$
DELIMITER ;

# Creating a new trigger to update stock levels once a sale takes place

DELIMITER $$
CREATE TRIGGER update_stock
    AFTER INSERT ON orderitems
    FOR EACH ROW 
    BEGIN
    UPDATE stock
    SET
	stocklevel = stocklevel - new.quantitysold
    where StockID = new.stockID;
END$$
DELIMITER ;

# Inserting a new row into the sales

USE DRONE_STORE;
INSERT INTO orderitems (BarCode, StockID, item, QuantitySold, SalePrice, VAT, OrderID)
VALUES ('52667-2423', '12', 'Multi Rotor Drone', '1', '€1257,46', '€0,00', '121212');

#Resolution of Exercise 2
# Checking if Stock Level changed

SELECT * FROM drone_store.stock;

# Checking if changes were recorded in the audit table

SELECT * FROM drone_store.stock_audit;

# Creating view for Exercise 3
Use drone_store;
Create VIEW Exercise3 AS
SELECT suppliers.SupplierID, suppliers.SupName, stock.ItemTitle, stock.CostPrice, stock.StockLevel
FROM suppliers
INNER JOIN stock
ON suppliers.SupplierID = stock.SupplierID
ORDER BY SupplierID DESC;

# Creating a table in the DataMart with the view
# Inserting the data created in the view (drone_store) to my DataMart
USE DataMart;
Create Table DataMart.Exercise3_Data SELECT * FROM drone_store.exercise3;

# Resolution to Exercise 3
USE DataMart;
SELECT * FROM exercise3_data;

# Creating view for Exercise 4
# Using right join because there are more orders than stock and suppliers

Use drone_store;
Create VIEW Exercise4 AS
SELECT stock.supplierID, stock.stockID, orders.orderid, orderitems.quantitysold, orderitems.saleprice
FROM stock
RIGHT JOIN orderitems
ON stock.stockID = orderitems.orderid
right join orders
ON orderitems.orderid = orders.orderid
order BY stock.SupplierID;

# Creating a table in the DataMart with the view
# Inserting the data created in the view (drone_store) to my DataMart
USE DataMart;
Create Table DataMart.Exercise4_Data SELECT * FROM drone_store.exercise4; 

# Resolution to Exercise 4
USE DataMart;
SELECT * FROM exercise4_data
order BY supplierID;

# Resolution to exercise 5
# Using SUBSTRING because my prices have the symbol €

USE drone_store;
SELECT coalesce (orderitems.item,'GrandTotal') AS Salesbyitem,
Sum(SUBSTRING(orderitems.SalePrice, 2)) as SummorizedPurchaseAmt
FROM orderitems
INNER JOIN orders
ON orderitems.orderID = orders.orderid
WHERE orders.ordersdate BETWEEN '2020-03-01' AND '2020-03-31'
GROUP BY Salesbyitem WITH ROLLUP;

# Resolution to exercise 6
# Using SUBSTRING because my prices have the symbol €

USE drone_store;
SELECT coalesce (orderitems.item,'GrandTotal') AS Salesbyitem2020,
Sum(SUBSTRING(orderitems.SalePrice, 2)) as TotalSales
FROM orderitems
INNER JOIN orders
ON orderitems.orderID = orders.orderid
WHERE orders.ordersdate BETWEEN '2020-01-01' AND '2020-03-31'
GROUP BY Salesbyitem2020 WITH ROLLUP;

# Resolution to exercise 7
# Using SUBSTRING because my prices have the symbol €

USE drone_store;
SELECT MONTHNAME(orders.ordersdate) AS '2019',
count(distinct(orders.orderid)) as NumberofOrders,
Sum(SUBSTRING(orderitems.SalePrice, 2)) as TotalSales
FROM orderitems
INNER JOIN orders
ON orderitems.orderID = orders.orderid
WHERE orders.ordersdate BETWEEN '2019-01-01' AND '2019-12-31'
GROUP BY MONTH(orders.ordersdate) WITH ROLLUP
ORDER BY orders.ordersdate;

# Resolution to exercise 8
# Using SUBSTRING because my prices have the symbol €

USE drone_store;
SELECT YEAR(orders.ordersdate) AS 'Year',
MONTHNAME(orders.ordersdate) AS 'Month',
count(distinct(orders.orderid)) as NumberofOrders,
Sum(SUBSTRING(orderitems.SalePrice, 2)) as TotalSales,
((sum((SUBSTRING(orderitems.SalePrice, 2)) / 1429204)*100)) as percentage
FROM orderitems
INNER JOIN orders
ON orderitems.orderID = orders.orderid
WHERE orders.ordersdate BETWEEN '2019-01-01' AND '2020-03-31'
GROUP BY MONTH(orders.ordersdate) WITH ROLLUP
ORDER BY orders.ordersdate;
