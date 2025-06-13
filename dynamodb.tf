resource "aws_dynamodb_table" "clients" {
  name         = var.clients_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "client_name"

  attribute {
    name = "client_name"
    type = "S"
  }

  ttl {
    attribute_name = ""
    enabled        = false
  }

  point_in_time_recovery {
    enabled = false
  }

  server_side_encryption {
    enabled = true
  }
}

resource "aws_dynamodb_table_item" "client_initial" {
  table_name = aws_dynamodb_table.clients.name
  hash_key   = aws_dynamodb_table.clients.hash_key

  item = <<ITEM
{
  "client_name": {"S": "sergio"},
  "email": {"S": "sergiogg1259@gmail.com"} 
}
ITEM
}

resource "aws_dynamodb_table_item" "other_client" {
  table_name = aws_dynamodb_table.clients.name
  hash_key   = aws_dynamodb_table.clients.hash_key

  item = <<ITEM
{
  "client_name": {"S": "otro cliente"},
  "email": {"S": "l_guanilo_e@hotmail.com"} 
}
ITEM
}

resource "aws_dynamodb_table_item" "other_client1" {
  table_name = aws_dynamodb_table.clients.name
  hash_key   = aws_dynamodb_table.clients.hash_key

  item = <<ITEM
{
  "client_name": {"S": "otro cliente1"},
  "email": {"S": "lordalex.hr@gmail.com"} 
}
ITEM
}

resource "aws_dynamodb_table_item" "other_client2" {
  table_name = aws_dynamodb_table.clients.name
  hash_key   = aws_dynamodb_table.clients.hash_key

  item = <<ITEM
{
  "client_name": {"S": "otro cliente2"},
  "email": {"S": "lcarranzal1@upao.edu.pe"} 
}
ITEM
}