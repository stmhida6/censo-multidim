# syntax=docker/dockerfile:1

# Este Dockerfile se construye con el contexto en la raíz del repositorio
# (ver docker-compose.yml) porque Censo.Api referencia a Censo.Aplicacion,
# Censo.Infraestructura y (transitivamente) Censo.Dominio.

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copiar solo los .csproj primero para aprovechar el cache de capas de Docker
COPY src/Censo.Api/Censo.Api.csproj src/Censo.Api/
COPY src/Censo.Aplicacion/Censo.Aplicacion.csproj src/Censo.Aplicacion/
COPY src/Censo.Dominio/Censo.Dominio.csproj src/Censo.Dominio/
COPY src/Censo.Infraestructura/Censo.Infraestructura.csproj src/Censo.Infraestructura/
RUN dotnet restore src/Censo.Api/Censo.Api.csproj

# Copiar el resto del código fuente y publicar
COPY src/ src/
RUN dotnet publish src/Censo.Api/Censo.Api.csproj -c Release -o /app/publish --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app
# La imagen base de .NET 8 ya incluye el usuario sin privilegios "app"
USER app
COPY --from=build /app/publish .
EXPOSE 8080
ENTRYPOINT ["dotnet", "Censo.Api.dll"]
