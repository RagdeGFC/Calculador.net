# Usar una imagen base de .NET SDK (para construir la aplicación)
# Asumo .NET 8.0, pero cámbialo si usas otra versión (ej. 6.0, 7.0)
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /app

# Copiar el archivo de la solución y los archivos de proyecto .csproj para restaurar las dependencias
# Esto ayuda a que Docker cachee mejor las dependencias
COPY ["calculadora.sln", "./"]
COPY ["src/src.csproj", "src/"]

# Restaurar las dependencias de NuGet para el proyecto src
RUN dotnet restore "src/src.csproj"

# Copiar el resto del código fuente del proyecto src
COPY . .

# Cambiar al directorio del proyecto src para construirlo y publicarlo
WORKDIR /app/src

# Publicar la aplicación para producción
# El comando /p:UseAppHost=false es importante para compatibilidad con contenedores
RUN dotnet publish "src.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Usar una imagen base de .NET Runtime (más pequeña y segura para ejecutar la aplicación)
# Debe coincidir con la versión del SDK usada arriba
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app

# Copiar los archivos publicados de la etapa de "build" a la etapa "final"
COPY --from=build /app/publish .

# Exponer el puerto en el que la aplicación ASP.NET Core escuchará
# Render asignará un puerto dinámico a través de la variable de entorno PORT,
# y ASP.NET Core está diseñado para escuchar en el puerto 80 por defecto dentro del contenedor.
EXPOSE 80

# Comando para iniciar la aplicación
# "src.dll" es el archivo ejecutable de tu proyecto (nombre de tu .csproj + .dll)
ENTRYPOINT ["dotnet", "src.dll"]