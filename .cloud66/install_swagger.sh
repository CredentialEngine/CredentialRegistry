wget https://github.com/swagger-api/swagger-ui/archive/v2.2.3.zip
tar xzvf v2.2.3.zip
mv swagger-ui-2.2.3/dist $STACK_PATH/public/swagger
rm -rf swagger-ui-2.2.3/
sed -i -e 's,http://petstore.swagger.io/v2,,g' $STACK_PATH/public/swagger/index.html
