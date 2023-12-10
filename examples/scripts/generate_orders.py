import csv
import random
from faker import Faker
from kestra import Kestra

fake = Faker()

# Define the list of columns for the CSV file
columns = ['order_id', 'customer_name', 'customer_email', 'product_id', 'price', 'quantity', 'total']

# Generate 100 random orders
orders = []
for i in range(100):
    order_id = i + 1
    customer_name = fake.name()
    customer_email = fake.email()
    product_id = random.randint(1, 20)
    price = round(random.uniform(10.0, 200.0), 2)
    quantity = random.randint(1, 10)
    total = round(price * quantity, 2)
    orders.append([order_id, customer_name, customer_email, product_id, price, quantity, total])

# Write the orders to a CSV file
with open('orders.csv', 'w', newline='') as file:
    writer = csv.writer(file)
    writer.writerow(columns)
    writer.writerows(orders)

# Calculate and print the sum and average of the "total" column
total_sum = sum(order[6] for order in orders)
average_order = round(total_sum / len(orders), 2)
print(f'Total sum: {total_sum}')
print(f'Average Order value: {average_order}')

Kestra.outputs({'total_sum': total_sum, 'average_order': average_order})
