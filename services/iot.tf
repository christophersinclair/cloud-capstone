resource "aws_iot_thing_type" "fauna_thing_type" {
    name = "fauna-thing-type-REPLACE_ME_UUID"
    properties {
      description = "Fauna wildlife sensor"
    }   
}

resource "aws_iot_thing" "fauna_iot" {
    name = "fauna-iot-REPLACE_ME_UUID"
    thing_type_name = aws_iot_thing_type.fauna_thing_type.name
}