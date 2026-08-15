FROM tomcat:9.0-jdk17-temurin

RUN rm -rf /usr/local/tomcat/webapps/*

COPY target/helloworld-1.0-SNAPSHOT.war /usr/local/tomcat/webapps/helloworld.war

EXPOSE 8080

CMD ["catalina.sh", "run"]
