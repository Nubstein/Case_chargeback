--Verificar se existem valores nulos na tabela. Neste caso 1= sim, e 0 = não
--ou seja, onde houver valor nulo, somará 1

SELECT COUNT(*) total, 
SUM(IF(transaction_id IS NULL, 1, 0)) transaction_id, 
SUM(IF(merchant_id IS NULL, 1, 0)) merchant_id, 
SUM(IF(user_id IS NULL, 1, 0)) user_id,
SUM(IF(card_number IS NULL, 1, 0)) card_number,
SUM(IF(transaction_date IS NULL, 1, 0)) transaction_date,
SUM(IF(transaction_amount IS NULL, 1, 0)) transaction_amount,
SUM(IF(device_id IS NULL, 1, 0)) device_id,
SUM(IF(has_cbk IS NULL, 1, 0)) has_cbk,
FROM `case-377312.transactional_sample.transactional-sample`

-----------------------------------------------------------------------------------
--Formatei a tabela para data dd/mm/aa extraí a hora em coluna separada 
--Adicionei uma coluna com horário supeito para identificar se a compra foi feita de madrugada

SELECT
transaction_id,
merchant_id,
user_id,
card_number,
device_id,
transaction_amount,
has_cbk,
transaction_date,
FORMAT_TIMESTAMP("%d/%m/%Y %H:%M:%S", transaction_date) AS formatted_date,
EXTRACT(HOUR FROM transaction_date) AS hour,
  CASE WHEN EXTRACT(HOUR FROM transaction_date) 
    BETWEEN 0 AND 5 THEN 'Madrugada' 
                    ELSE 'Horario Normal' 
                    END AS time_suspicious
FROM `case-377312.transactional_sample.transactional-sample`

-----------------------------------------------------------------------------------

--Dados Gerais

SELECT 
COUNT(transaction_id) AS n_transactions,
ROUND(SUM(transaction_amount),2) AS total_amount,
COUNT(DISTINCT(merchant_id)) AS n_merchants,
COUNT(DISTINCT(user_id)) AS n_users,
COUNT(DISTINCT(card_number)) AS n_cards,
COUNT(DISTINCT(device_id)) AS n_devices,
MIN(formatted_date) AS first_trans,
MAX(formatted_date) AS last_trans
 FROM `case-377312.transactional_sample.formatted_date` 

-----------------------------------------------------------------------------------


/* Nº de transações com chargeback: 391 , sendo 12% do total das transações. 
E o valor total das transações com chargeback é de $ 568.346,62 sendo 23% do valor total das transações.*/

SELECT
  COUNT(transaction_id) AS total_transactions,
  SUM(transaction_amount) AS total_amount,
  has_cbk,
FROM `case-377312.transactional_sample.transactional-sample` 
GROUP BY has_cbk;


-----------------------------------------------------------------------------------

--Tabela com o número de transações realizadas por dia e quantidade de chargeback em cada dia
--Tive que repetir o FORMAT_DATE("%d/%m/%Y", transaction_date) no GROUP BY 


SELECT 
FORMAT_DATE("%d/%m/%Y", transaction_date) AS _date, 
       COUNT(transaction_id) AS total_transactions,
       SUM(CASE WHEN has_cbk THEN 1 ELSE 0 END) AS total_chargebacks
FROM `case-377312.transactional_sample.formatted_date`
GROUP BY _date

-----------------------------------------------------------------------------------

--Dados gerais por merchant

SELECT 
merchant_id, 
COUNT(DISTINCT(user_id)) AS n_customers,                                 
ROUND(AVG(transaction_amount), 1) AS avg_amount,   
ROUND(MIN(transaction_amount), 1) AS min_amount,   
ROUND(MAX(transaction_amount), 1) AS max_amount,   
ROUND(SUM(transaction_amount), 1) AS total_amount, 
COUNT(transaction_id) AS n_trans,
SUM(CASE WHEN has_cbk = true THEN 1 ELSE 0 END) AS trans_with_cbk,
SUM(CASE WHEN has_cbk = false THEN 1 ELSE 0 END) AS trans_without_cbk,   
ROUND(SUM(transaction_amount),2) AS amount_cbk_merch,
FROM `case-377312.transactional_sample.transactional-sample` 
GROUP BY merchant_id
ORDER BY trans_with_cbk DESC, amount_cbk_merch

-----------------------------------------------------------------------------------

--Dados gerais por usuário

SELECT 
user_id, 
COUNT(DISTINCT(merchant_id)) AS dist_merch,
ROUND(AVG(transaction_amount), 1) AS avg_amount,
ROUND(MIN(transaction_amount), 1) AS min_amount,
ROUND(MAX(transaction_amount), 1) AS max_amount,
ROUND(SUM(transaction_amount), 1) AS total_amount,
COUNT(transaction_id) AS n_trans,
SUM(CASE WHEN has_cbk = true THEN 1 ELSE 0 END) AS trans_with_cbk,
SUM(CASE WHEN has_cbk = false THEN 1 ELSE 0 END) AS trans_without_cbk,
ROUND(SUM(transaction_amount),2) AS amount_cbk_user,
FROM `case-377312.transactional_sample.transactional-sample` 
GROUP BY user_id
ORDER BY trans_with_cbk DESC, amount_cbk_user DESC;

-----------------------------------------------------------------------------------

--Quantos dispositivos cada usário utiliza?

SELECT  
user_id,
COUNT(DISTINCT(device_id)) AS dist_device
FROM `case-377312.transactional_sample.formatted_date` 
GROUP BY user_id
ORDER BY dist_device DESC
-----------------------------------------------------------------------------------

--Quantos cartões cada usário utiliza?

SELECT  
user_id,
COUNT(DISTINCT(card_number)) AS dist_card
FROM `case-377312.transactional_sample.formatted_date` 
GROUP BY user_id
ORDER BY dist_card DESC

-----------------------------------------------------------------------------------

/* Quantos cartões cada usuário utiliza? Existe alguma relação entre usuarios com mt cartões e cbks? 
Parece que sim. Os usuários com muitos cartões realizaram mts transações de cbk
Ex: O usuário 11750 realizou 25 trans que foram cbk com 25 cartões diferentes.*/

SELECT 
user_id,
has_cbk,
COUNT (DISTINCT(card_number)) AS n_distinct_cards_user,
COUNT(transaction_id) AS n_trans
 FROM `case-377312.transactional_sample.formatted_date` 
 GROUP BY user_id, has_cbk
 ORDER BY n_distinct_cards_user DESC

-----------------------------------------------------------------------------------

--Quem sao os usuários dos cartões com mais cbk?

SELECT 
user_id,
card_number,
SUM(CASE WHEN has_cbk = true THEN 1 ELSE 0 END) AS trans_with_cbk,
SUM(CASE WHEN has_cbk = false THEN 1 ELSE 0 END) AS trans_without_cbk,
FROM `case-377312.transactional_sample.transactional-sample`
GROUP BY card_number, user_id
ORDER BY trans_with_cbk DESC

-----------------------------------------------------------------------------------

/* Será que existe alguma relação entre dispositivos desconhecidos e fraude?

67/763 = 8,78% das transações realizadas por dispositivos desconhecidos cometeram fraude em valores médios de 1.671
enquanto 324/2045= 15,84% das transações realizadas por dispositivos conhecidos cometeram fraude em valores médios de 1.408
Embora os valores médios de casos de fraude sejam maiores em dispositivos não conhecidos
houve mais transações fraudulantes realizadas em dispositivos conhecidos */

SELECT 
COUNT(transaction_id) AS n_trans,
has_cbk,
ROUND(AVG(transaction_amount), 1) AS avg_amount,
CASE WHEN device_id IS NULL THEN 'No' ELSE 'Yes' END AS device_known
 FROM `case-377312.transactional_sample.formatted_date` 
  GROUP BY has_cbk, device_known
  ORDER BY device_known

-----------------------------------------------------------------------------------

/*Será que existe correlação entre chargebacks e compras realizadas de madrugada?
Das 2853 trans feitas em 'horario normal', 331 sao cbk, ou seja 13% 
E das 346 trans feitas na 'Madrugada', 60 são cbk, ou seja, 17,34%
sendo gasto em média 1.263,9 em cbk cometidas de madrugada e 1.487,9 em fraudes em horario normal
Existe um pequeno aumento em cbk durante a madrugada, mas não é mt significativo
*/

SELECT 
COUNT(transaction_id) AS n_trans,
ROUND(AVG(transaction_amount), 1) AS avg_trans_amount,
COUNT (DISTINCT(user_id)) as n_users,
has_cbk,
time_suspicious
 FROM `case-377312.transactional_sample.formatted_date` 
  GROUP BY time_suspicious, has_cbk, time_suspicious
  ORDER BY time_suspicious

-----------------------------------------------------------------------------------

--Dados gerais por usuário
--5 primeiros usuários utilizaram muitos cartões diferentes,
--5 primeiros usuários com muitos chargebacks
--5 primeiros usuários de cartoes com muitos chargebacks

SELECT 
user_id,
time_suspicious,
COUNT(DISTINCT(card_number)) AS dist_cards,
COUNT(DISTINCT(merchant_id)) AS dist_merch,
ROUND(SUM(transaction_amount), 1) AS total_,
COUNT(transaction_id) AS n_trans,
SUM(CASE WHEN has_cbk = true THEN 1 ELSE 0 END) AS with_cbk,
SUM(CASE WHEN has_cbk = false THEN 1 ELSE 0 END) AS without_cbk,
ROUND(SUM(transaction_amount),2) AS amount_cbk_user,
FROM `case-377312.transactional_sample.formatted_date` 
WHERE user_id IN (11750, 91637, 79054, 96025, 78262, 75710, 21768, 86411, 58905, 28218)
GROUP BY user_id, time_suspicious
ORDER BY with_cbk DESC, amount_cbk_user DESC;
