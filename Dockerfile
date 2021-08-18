FROM wessaunders/gdal:latest

ENV GEOSERVER_VERSION 2.19.1

# build gdal.jar
RUN apt-get -qq update \
    && apt-get -qq -y --no-install-recommends install openjdk-11-jdk 

ENV JAVA_HOME /usr/lib/jvm/java-11-openjdk-amd64

ENV MRSID_VERSION 9.5.4.4709-rhel6.x86-64.gcc482
ENV MRSID_NAME MrSID_DSDK-$MRSID_VERSION

# Install Geoserver
ENV GEOSERVER_HOME /opt/geoserver
ENV GDAL_PATH /usr/local/src
ENV GDAL_DATA $GDAL_PATH/gdal-$GDAL_VERSION
ENV LD_LIBRARY_PATH /usr/lib/jni:/usr/share/java:/usr/local/src/$MRSID_NAME/Raster_DSDK/lib:/usr/local/src/$MRSID_NAME/Raster_DSDK/lib:/opt/mrsid/Lidar_DSDK/lib:/usr/local/bin

WORKDIR $JAVA_HOME

RUN mkdir $JAVA_HOME/jre && \
    mkdir $JAVA_HOME/jre/lib && \
    mkdir $JAVA_HOME/jre/lib/ext && \
    mkdir $JAVA_HOME/jre/lib/amd64

# Get native JAI and ImageIO
RUN \
    cd $JAVA_HOME && \
    wget http://download.java.net/media/jai/builds/release/1_1_3/jai-1_1_3-lib-linux-amd64.tar.gz -O - | tar -xz && \
    mv $JAVA_HOME/jai-1_1_3/lib/*.jar $JAVA_HOME/jre/lib/ext/ && \
    mv $JAVA_HOME/jai-1_1_3/lib/*.so $JAVA_HOME/jre/lib/amd64/ && \
    rm -r $JAVA_HOME/jai-1_1_3

RUN \
    cd $JAVA_HOME && \
    export _POSIX2_VERSION=199209 &&\
    wget http://download.java.net/media/jai-imageio/builds/release/1.1/jai_imageio-1_1-lib-linux-amd64.tar.gz -O - | tar -xz && \
    mv $JAVA_HOME/jai_imageio-1_1/lib/*.jar $JAVA_HOME/jre/lib/ext/ && \
    mv $JAVA_HOME/jai_imageio-1_1/lib/*.so $JAVA_HOME/jre/lib/amd64/ && \
    rm -r $JAVA_HOME/jai_imageio-1_1

#
# GEOSERVER INSTALLATION
#
ENV GEOSERVER_URL http://sourceforge.net/projects/geoserver/files/GeoServer/$GEOSERVER_VERSION
WORKDIR /

# Get GeoServer
RUN wget -c $GEOSERVER_URL/geoserver-$GEOSERVER_VERSION-bin.zip -O ~/geoserver.zip && \
    unzip ~/geoserver.zip -d /opt && \
    mkdir /opt/.geoserver

RUN mv -v /opt/* /opt/.geoserver && \
    rm ~/geoserver.zip

RUN mv /opt/.geoserver $GEOSERVER_HOME

WORKDIR /opt

# Get Pyramid plugin
ENV PLUGIN pyramid
RUN wget -c $GEOSERVER_URL/extensions/geoserver-$GEOSERVER_VERSION-$PLUGIN-plugin.zip -O ~/geoserver-$PLUGIN-plugin.zip && \
    unzip -o ~/geoserver-$PLUGIN-plugin.zip -d /opt/geoserver/webapps/geoserver/WEB-INF/lib/ && \
    rm ~/geoserver-$PLUGIN-plugin.zip

# Get GDAL plugin
ENV PLUGIN gdal
RUN wget -c $GEOSERVER_URL/extensions/geoserver-$GEOSERVER_VERSION-$PLUGIN-plugin.zip -O ~/geoserver-$PLUGIN-plugin.zip && \
    unzip -o ~/geoserver-$PLUGIN-plugin.zip -d /opt/geoserver/webapps/geoserver/WEB-INF/lib/ && \
    rm ~/geoserver-$PLUGIN-plugin.zip

# Get import plugin
ENV PLUGIN importer
RUN wget -c $GEOSERVER_URL/extensions/geoserver-$GEOSERVER_VERSION-$PLUGIN-plugin.zip -O ~/geoserver-$PLUGIN-plugin.zip && \
    unzip -o ~/geoserver-$PLUGIN-plugin.zip -d /opt/geoserver/webapps/geoserver/WEB-INF/lib/ && \
    rm ~/geoserver-$PLUGIN-plugin.zip

# Replace GDAL Java bindings
RUN ls $GEOSERVER_HOME/webapps/geoserver/WEB-INF/lib/
RUN rm -rf $GEOSERVER_HOME/webapps/geoserver/WEB-INF/lib/imageio-ext-gdal-bindings-1.9.2.jar
RUN cp /usr/local/src/gdal-$GDAL_VERSION/swig/java/gdal.jar $GEOSERVER_HOME/webapps/geoserver/WEB-INF/lib/gdal.jar
RUN cp /usr/local/src/gdal-$GDAL_VERSION/swig/java/*.so /usr/share/java
COPY web.xml $GEOSERVER_HOME/webapps/geoserver/WEB-INF/web.xml
RUN ls $GEOSERVER_HOME/webapps/geoserver/WEB-INF/lib/

# Expose GeoServer's default port
EXPOSE 8080

CMD ["/opt/geoserver/bin/startup.sh"]
