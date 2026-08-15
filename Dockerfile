FROM tomcat:9.0-jdk17-temurin

RUN rm -rf /usr/local/tomcat/webapps/*

COPY target/helloworld.war /usr/local/tomcat/webapps/helloworld.war

EXPOSE 8080

CMD ["catalina.sh", "run"]
