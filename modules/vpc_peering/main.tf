# requester_vpc_id에서 accepter_vpc_id로 VPC Peering 요청을 보내며, 같은 계정+리전이므로 auto_accept = true로 설정해 자동 수락 처리함.
resource "aws_vpc_peering_connection" "this" {
  vpc_id        = var.requester_vpc_id
  peer_vpc_id   = var.accepter_vpc_id
  auto_accept   = var.auto_accept

  # 두 VPC 간에 서로의 프라이빗 DNS 레코드를 DNS 이름으로 조회 가능하도록 설정함.
  requester {
    allow_remote_vpc_dns_resolution = true
  }

  accepter {
    allow_remote_vpc_dns_resolution = true
  }

  tags = {
    Name        = "${var.component}-peer"
    component   = var.component
    type        = "vpc-peering"
    environment = var.env
    managed_by  = "terraform"
  }
}

# 요청자 VPC의 라우팅 테이블에 수락자 VPC의 CIDR로 가는 트래픽은 해당 VPC 피어링 연결로 전송하라는 라우팅 경로를 설정
resource "aws_route" "requester_to_accepter" {
  for_each = toset(compact(var.requester_route_table_ids))

  route_table_id            = each.value
  destination_cidr_block    = var.accepter_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.this.id
}

# 수락자 VPC의 라우팅 테이블에도 요청자 VPC로 향하는 경로를 설정함
resource "aws_route" "accepter_to_requester" {
  for_each = toset(compact(var.accepter_route_table_ids))

  route_table_id            = each.value
  destination_cidr_block    = var.requester_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.this.id
}