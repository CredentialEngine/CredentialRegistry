wget https://github.com/swagger-api/swagger-ui/archive/v3.0.5.zip
unzip  v3.0.5.zip
mv swagger-ui-3.0.5/dist $STACK_PATH/public/swagger
rm -rf swagger-ui-3.0.5/
rm v3.0.5.zip
sed -i -e 's,http://petstore.swagger.io/v2,,g' $STACK_PATH/public/swagger/index.html
