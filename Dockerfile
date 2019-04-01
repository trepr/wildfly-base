FROM trepr/jdk8-base:latest
LABEL maintainer="TRE-PR/SECTI/COSIS/Seção de Desenvolvimento de Sistemas <sds@tre-pr.jus.br>" \
      description="Imagem docker base wildfly"

# Set the WILDFLY_VERSION env variable
ENV WILDFLY_VERSION 16.0.0.Final
ENV WILDFLY_SHA1 287c21b069ec6ecd80472afec01384093ed8eb7d
ENV JBOSS_HOME /opt/jboss/wildfly

USER root

# 1. Create a user and group used to launch processes
#    The user ID 1000 is the default for the first "regular" user on Fedora/RHEL,
#    so there is a high chance that this ID will be equal to the current user
#    making it easier to use volumes (no permission issues)
# 2. Add the WildFly distribution to /opt, and make wildfly the owner of the extracted tar content
#    Make sure the distribution is available from a well-known place
# 3. Creates /run/secrets directory and set owner to jboss
#    ???? aparently this doesnt work
RUN groupadd -r jboss -g 1000 \
    && useradd -u 1000 -r -g jboss -m -d /opt/jboss -s /sbin/nologin -c "JBoss user" jboss \
    && chmod 755 /opt/jboss \
    && cd $HOME \
    && curl -O https://download.jboss.org/wildfly/$WILDFLY_VERSION/wildfly-$WILDFLY_VERSION.tar.gz \
    && sha1sum wildfly-$WILDFLY_VERSION.tar.gz | grep $WILDFLY_SHA1 \
    && tar xf wildfly-$WILDFLY_VERSION.tar.gz \
    && mv $HOME/wildfly-$WILDFLY_VERSION $JBOSS_HOME \
    && rm wildfly-$WILDFLY_VERSION.tar.gz \
    && chown -R jboss:0 ${JBOSS_HOME} \
    && chmod -R ug+rw ${JBOSS_HOME}
#    && mkdir -p /run/secrets \
#    && chown -R jboss:jboss /run/secrets
    
# Ensure signals are forwarded to the JVM process correctly for graceful shutdown
ENV LAUNCH_JBOSS_IN_BACKGROUND true

# Switch back to jboss user
USER jboss

# Set the working directory
WORKDIR $JBOSS_HOME

# Expose the ports we're interested in
EXPOSE 8009 8080 9990

# Set the default command to run on boot
# This will boot WildFly in the standalone mode and bind to all interface
CMD ["/opt/jboss/wildfly/bin/standalone.sh", "--server-config=standalone-full.xml", "-b=0.0.0.0", "-bmanagement=0.0.0.0"]
