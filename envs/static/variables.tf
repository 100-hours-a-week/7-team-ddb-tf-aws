variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-2"
}

variable "common_tags" {
  description = "모든 리소스에 적용할 공통 태그"
  type        = map(string)
  default = {
    Environment = "static"
    Owner       = "dolpin"
  }
}

variable "env" {
  description = "환경"
  type        = string
  default     = "static"
}

variable "lambda_schedules" {
  type = map(object({
    schedule_expression          = string
    action                       = string
    env                          = string
  }))
  default = {
    # 운영환경 ON (평일 10시)
    prod_on = {
      schedule_expression          = "cron(30 9 ? * MON-FRI *)"
      action                       = "start"
      env                          = "prod"
    }

    # 운영환경 OFF (평일 20시)
    prod_off = {
      schedule_expression          = "cron(0 20 ? * MON-FRI *)"
      action                       = "stop"
      env                          = "prod"
    }

    # 개발환경 ON (일~목 13시)
    dev_on_weekday = {
      schedule_expression          = "cron(30 12 ? * SUN-THU *)"
      action                       = "start"
      env                          = "dev"
    }

    # 개발환경 ON (금요일 9시)
    dev_on_friday = {
      schedule_expression          = "cron(30 8 ? * FRI *)"
      action                       = "start"
      env                          = "dev"
    }

    # 개발환경 ON (토요일 13시)
    dev_on_saturday = {
      schedule_expression          = "cron(30 12 ? * SAT *)"
      action                       = "start"
      env                          = "dev"
    }

    # 개발환경 OFF (일~금 23시)
    dev_off_weekday = {
      schedule_expression          = "cron(0 23 ? * SUN-FRI *)"
      action                       = "stop"
      env                          = "dev"
    }

    # 개발환경 OFF (토요일 → 일요일 새벽 4시)
    dev_off_saturday = {
      schedule_expression          = "cron(0 4 ? * SAT *)"
      action                       = "stop"
      env                          = "dev"
    }

    # shared ON: 모든 시작 시간
    shared_on_weekday = {
      schedule_expression          = "cron(30 9 ? * MON-THU *)"
      action                       = "start"
      env                          = "shared"
    }

    # shared ON: 금 오전 8시 30분
    shared_on_friday = {
      schedule_expression          = "cron(30 8 ? * FRI *)"
      action                       = "start"
      env                          = "shared"
    }

    # shared ON: 토, 일 오후 12시 30분
    shared_on_weekend = {
      schedule_expression          = "cron(30 12 ? * SAT,SUN *)"
      action                       = "start"
      env                          = "shared"
    }
    # 일~금 오후 11시 종료
    shared_off_sun_to_fri = {
      schedule_expression          = "cron(0 23 ? * SUN-FRI *)"
      action                       = "stop"
      env                          = "shared"
    }

    # 일요일 오전 4시 종료
    shared_off_sun_morning = {
      schedule_expression          = "cron(0 4 ? * SUN *)"
      action                       = "stop"
      env                          = "shared"
    }
  }
}
