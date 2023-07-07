#Câu 1: Những sản phẩm nào chúng ta nên đặt hàng nhiều hơn hoặc ít hơn? 
# -> báo cáo hàng tồn kho, bao gồm lượng hàng sắp hết (sản phẩm đang có nhu cầu) và hiệu suất sản phẩm
#Câu 2: Chúng ta nên điều chỉnh các chiến lược tiếp thị và truyền thông như thế nào cho phù hợp với hành vi của khách hàng?
#-> phân loại khách hàng, tìm khách hàng VIP

select count(productCode) as SOSPDN from products
# -> DN đang kinh doanh 110 sản phẩm

select productCode,productName,productLine, quantityInStock as SOLUONGTONKHO from products
group by productCode 
order by quantityInStock asc 
#-> Có 7 code sản phẩm đang có lượng stock kho dưới 1,000 sản phẩm

select o.productCode,p.productName,p.productLine, sum(o.quantityOrdered) as SOLUONGDATHANG, p.quantityInStock as SOLUONGTONKHO from orderdetails o
inner join products p  
on p.productCode = o.productCode 
group by o.productCode 
order by SOLUONGTONKHO ASC
#-> có 109 sản phẩm được đặt hàng so với tổng 110 sản phẩm được bán ra

select * from products p 
where productCode not in (select distinct productCode from orderdetails )
#-> sản phẩm code S18_3233 dòng Classic Cars không có đơn đặt hàng

with COMPARE_STOCK_VS_ORDER AS(
select o.productCode,p.productName,p.productLine, sum(o.quantityOrdered) as SOLUONGDATHANG, p.quantityInStock as SOLUONGTONKHO from orderdetails o
inner join products p  
on p.productCode = o.productCode 
group by o.productCode 
order by SOLUONGTONKHO ASC)
select c.*, (SOLUONGDATHANG - SOLUONGTONKHO) as SOLUONGCANORDER
from COMPARE_STOCK_VS_ORDER as c
where SOLUONGTONKHO <= SOLUONGDATHANG
#-> đề xuất: lấy số lượng order làm min stock thì cần order thêm 1 số lượng được tính trong cột "SOLUONGCANORDER" với 11 code sản phẩm

with COMPARE_STOCK_VS_ORDER_1 AS(
select o.productCode,p.productName,p.productLine, sum(o.quantityOrdered) as SOLUONGDATHANG, p.quantityInStock as SOLUONGTONKHO from orderdetails o
inner join products p  
on p.productCode = o.productCode 
group by o.productCode 
order by SOLUONGTONKHO ASC)
select c1.* 
from COMPARE_STOCK_VS_ORDER_1 as c1
where SOLUONGTONKHO >= SOLUONGDATHANG
#-> đề xuất: nếu lấy số lượng Order làm min stock thì 98 code sản phẩm sẽ đặt hàng ít hơn hoặc không đặt hàng do số lượng tồn kho còn nhiều hơn số lượng đặt hàng lần trước

#Câu 2: Chúng ta nên điều chỉnh các chiến lược tiếp thị và truyền thông như thế nào cho phù hợp với hành vi của khách hàng?
#-> phân loại khách hàng, tìm khách hàng VIP, Khách hàng ít tham gia
#-> Tính Q1 và Q3 => nếu amount >= Q3     -> khách hàng VIP (75% -> 100%)
#						 Q3 < amount > Q1 -> khách hàng thân thiết (25% -> 75%)
#						 Q1 > amount 	  -> khách hàng ít tham gia ( < 25%)	
select c.customerNumber, c.customerName, p.amount 
from customers c 
inner join payments p 
on c.customerNumber = p.customerNumber 
group by p.customerNumber 
order by p.amount desc 

with PAYMENT_TỪNG_KHÁCH_HÀNG as (
select c.customerNumber, c.customerName, p.amount 
from customers c 
inner join payments p 
on c.customerNumber = p.customerNumber 
group by p.customerNumber 
order by p.amount desc )
select AVG(amount) AS Mean_amount
from PAYMENT_TỪNG_KHÁCH_HÀNG as P
#-> Mean của data là 30,018


SELECT p.amount  AS mode_value, COUNT(p.amount) AS occurrence_count
FROM payments p 
GROUP BY p.amount  
HAVING COUNT(p.amount) = (
    SELECT MAX(occurrence_count)
    FROM (
        SELECT COUNT(p.amount) AS occurrence_count
        FROM payments 
        GROUP BY p.amount 
    ) AS occurrence_Count 
    );
   #-> Tính mode
   
   

WITH PAYMENT_TUNG_KHACH_HANG AS (
    SELECT
        c.customerNumber,
        c.customerName,
        p.amount
    FROM
        customers c
    INNER JOIN payments p ON c.customerNumber = p.customerNumber
    GROUP BY
        p.customerNumber
    ORDER BY
        p.amount DESC
)
SELECT
    SUBSTRING_INDEX(SUBSTRING_INDEX(GROUP_CONCAT(p1.amount ORDER BY p1.amount), ',', FLOOR(0.25 * COUNT(*) + 1)), ',', -1) AS Q1,
    SUBSTRING_INDEX(SUBSTRING_INDEX(GROUP_CONCAT(p1.amount ORDER BY p1.amount), ',', FLOOR(0.75 * COUNT(*) + 1)), ',', -1) AS Q3
FROM
    PAYMENT_TUNG_KHACH_HANG p1;
#-> Q1 là 15183.83 và Q3 là 38785.48
   

WITH PAYMENT_TUNG_KHACH_HANG AS (
    SELECT 
        c.customerNumber,
        c.customerName,
        p.amount
    FROM
        customers c
    INNER JOIN payments p ON c.customerNumber = p.customerNumber
    GROUP BY
        p.customerNumber
    ORDER BY
        p.amount DESC
)
SELECT
    p1.*,
    CASE
        WHEN p1.amount > (
            SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(GROUP_CONCAT(amount ORDER BY amount), ',', FLOOR(0.75 * COUNT(*) + 1)), ',', -1) AS Q3
            FROM PAYMENT_TUNG_KHACH_HANG
        ) THEN "VIP"
        WHEN p1.amount < (
            SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(GROUP_CONCAT(amount ORDER BY amount), ',', FLOOR(0.25 * COUNT(*) + 1)), ',', -1) AS Q1
            FROM PAYMENT_TUNG_KHACH_HANG
        ) THEN "Khách hàng ít tham gia"
        ELSE "Thân thiết"
    END AS Cust_Seg
FROM PAYMENT_TUNG_KHACH_HANG AS p1;

WITH PAYMENT_TUNG_KHACH_HANG AS (
    SELECT 
        c.customerNumber,
        c.customerName,
        p.amount
    FROM
        customers c
    INNER JOIN payments p ON c.customerNumber = p.customerNumber
    GROUP BY
        p.customerNumber
    ORDER BY
        p.amount DESC
)
SELECT
    p1.*,
    CASE
        WHEN p1.amount > (
            SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(GROUP_CONCAT(amount ORDER BY amount), ',', FLOOR(0.75 * COUNT(*) + 1)), ',', -1) AS Q3
            FROM PAYMENT_TUNG_KHACH_HANG
        ) THEN "VIP"
        WHEN p1.amount < (
            SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(GROUP_CONCAT(amount ORDER BY amount), ',', FLOOR(0.25 * COUNT(*) + 1)), ',', -1) AS Q1
            FROM PAYMENT_TUNG_KHACH_HANG
        ) THEN "Khách hàng ít tham gia"
        ELSE "Thân thiết"
    END AS Cust_Seg
FROM PAYMENT_TUNG_KHACH_HANG AS p1


WITH PAYMENT_TUNG_KHACH_HANG AS (
    SELECT 
        c.customerNumber,
        c.customerName,
        p.amount
    FROM
        customers c
    INNER JOIN payments p ON c.customerNumber = p.customerNumber
    GROUP BY
        p.customerNumber
    ORDER BY
        p.amount DESC
),
COUNT_SEGMENT as (
SELECT
    p1.*,
    CASE
        WHEN p1.amount > (
            SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(GROUP_CONCAT(amount ORDER BY amount), ',', FLOOR(0.75 * COUNT(*) + 1)), ',', -1) AS Q3
            FROM PAYMENT_TUNG_KHACH_HANG
        ) THEN "VIP"
        WHEN p1.amount < (
            SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(GROUP_CONCAT(amount ORDER BY amount), ',', FLOOR(0.25 * COUNT(*) + 1)), ',', -1) AS Q1
            FROM PAYMENT_TUNG_KHACH_HANG
        ) THEN "Khách hàng ít tham gia"
        ELSE "Thân thiết"
    END AS Cust_Seg
FROM PAYMENT_TUNG_KHACH_HANG AS p1)
select Cust_Seg, count(Cust_Seg) as Tyle
from COUNT_SEGMENT 
group by Cust_Seg;

#-> insight: Đối với công ty khách hàng VIP -> tăng chiết khấu khi mua hàng theo doanh thu đóng góp 
#			VD: khách hàng VIP có mức chi tiêu trên 50.000 chiết khấu 2%
#				khách hàng VIP có mức chi tiêu trên 100.000 chiết khấu 5%
#	            khách hàng VIP có mức chi tiêu trên 200.000 chiết khấu 8%
#			 Đối với công ty khách hàng thân thiết -> tiếp tục đưa những chính sách khuyến mãi, tặng kèm quà khi mua hàng
#			VD: tặng kèm camera hành trình, nội thất xe, ...
#			 Đối với công ty khách hàng ít tham gia -> đẩy mạnh truyển thông bằng phương pháp quảng cáo (FB, mai,SMS,...) 
#													-> đưa ra các ưu đãi theo mùa, chính sách trả góp,...
#													-> quà tặng voucher