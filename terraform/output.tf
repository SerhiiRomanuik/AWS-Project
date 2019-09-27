output "instance_id" {
  value = "${aws_instance.inst1.*.id}"
}

output "db_endpoint"{
  value       = "${module.db.this_db_instance_endpoint}"
}
