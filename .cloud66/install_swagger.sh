cd $STACK_PATH/tmp
curl -L https://github.com/swagger-api/swagger-ui/archive/v2.2.3.zip | tar zx
mv $STACK_PATH/tmp/swagger-ui-2.2.3/dist $STACK_PATH/public/swagger
sed -i '' -e 's,http://petstore.swagger.io/v2,,g' $STACK_PATH/public/swagger/index.html
