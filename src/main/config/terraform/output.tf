output "urotaxiec2public_ip" {
    value = aws_instance.urotaxiec2.public_ip  
}
output "urotaxidbendpoint" {
    value = aws_db_instance.urotaxidb.endpoint 
}