function handler () {
    EVENT_DATA=$1

    aws s3 ls

    RESPONSE="{\"statusCode\": 200, \"body\": \"Hello from Lambda!\"}"
    echo $RESPONSE
}