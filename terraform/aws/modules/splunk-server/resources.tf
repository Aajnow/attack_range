

data "aws_ami" "latest-ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


resource "aws_instance" "splunk-server" {
  ami                    = data.aws_ami.latest-ubuntu.id
  instance_type          = var.config.instance_type_ec2
  key_name               = var.config.key_name
  subnet_id              = var.ec2_subnet_id
  vpc_security_group_ids = [var.vpc_security_group_ids]
  private_ip             = var.config.splunk_server_private_ip
  depends_on             = [var.phantom_server_instance]
  root_block_device {
    volume_type = "gp2"
    volume_size = "60"
    delete_on_termination = "true"
  }
  tags = {
    Name = "ar-splunk-${var.config.range_name}-${var.config.key_name}"
  }

  provisioner "remote-exec" {
    inline = ["echo booted"]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      host        = aws_instance.splunk-server.public_ip
      private_key = file(var.config.private_key_path)
    }
  }

  provisioner "local-exec" {
    working_dir = "../../../ansible"
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ubuntu --private-key ${var.config.private_key_path} -i '${aws_instance.splunk-server.public_ip},' playbooks/splunk_server.yml -e 'ansible_python_interpreter=/usr/bin/python3 splunk_admin_password=${var.config.attack_range_password} splunk_url=${var.config.splunk_url} splunk_binary=${var.config.splunk_binary} s3_bucket_url=${var.config.s3_bucket_url} splunk_escu_app=${var.config.splunk_escu_app} splunk_asx_app=${var.config.splunk_asx_app} splunk_windows_ta=${var.config.splunk_windows_ta} splunk_aws_ta=${var.config.splunk_aws_ta} splunk_cim_app=${var.config.splunk_cim_app} splunk_sysmon_ta=${var.config.splunk_sysmon_ta} splunk_sysmon_linux_ta=${var.config.splunk_sysmon_linux_ta} key_name=${var.config.key_name} splunk_python_app=${var.config.splunk_python_app} splunk_mltk_app=${var.config.splunk_mltk_app} caldera_password=${var.config.attack_range_password} install_es=${var.config.install_es} splunk_es_app=${var.config.splunk_es_app} phantom_app=${var.config.phantom_app} phantom_server=${var.config.phantom_server} phantom_byo=${var.config.phantom_byo} phantom_api_token=${var.config.phantom_api_token} phantom_byo_ip=${var.config.phantom_byo_ip} phantom_server_private_ip=${var.config.phantom_server_private_ip} phantom_admin_password=${var.config.attack_range_password} splunk_security_essentials_app=${var.config.splunk_security_essentials_app} splunk_bots_dataset=${var.config.splunk_bots_dataset} punchard_custom_visualization=${var.config.punchard_custom_visualization} status_indicator_custom_visualization=${var.config.status_indicator_custom_visualization} splunk_attack_range_dashboard=${var.config.splunk_attack_range_dashboard} timeline_custom_visualization=${var.config.timeline_custom_visualization} splunk_stream_app=${var.config.splunk_stream_app} splunk_ta_wire_data=${var.config.splunk_ta_wire_data} splunk_ta_stream=${var.config.splunk_ta_stream} splunk_zeek_ta=${var.config.splunk_zeek_ta} splunk_server_private_ip=${var.config.splunk_server_private_ip} splunk_office_365_ta=${var.config.splunk_office_365_ta} splunk_kinesis_ta=${var.config.splunk_kinesis_ta} splunk_linux_ta=${var.config.splunk_linux_ta} splunk_es_app_version=${var.config.splunk_es_app_version} install_dsp=${var.config.install_dsp} dsp_client_cert_path=${var.config.dsp_client_cert_path} dsp_node=${var.config.dsp_node} splunk_dashboard_beta=${var.config.splunk_dashboard_beta} ta_for_zeek=${var.config.ta_for_zeek} splunk_nginx_ta=${var.config.splunk_nginx_ta}'"
  }
}

resource "aws_eip" "splunk_ip" {
  count    = var.config.use_elastic_ips == "1" ? 1 : 0
  instance = aws_instance.splunk-server.id
}
