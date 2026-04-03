-- =============================================
-- Author:		А.Никитин
-- Create date: 17.04.2022
-- Description:	SDWH-41 Разработать отчет Поддерживаемые устройства
-- =============================================
CREATE PROC [dbo].[Report_SupportedDevice_Smart]
	@Mode nvarchar(100) = 'device'
AS
BEGIN
	SET NOCOUNT ON;

	--DECLARE @c1310 char(2) = char(13)+char(10)

	IF @Mode IS NULL BEGIN
		SELECT @Mode = 'device' --Поддерживаемые устройства
	END

	IF @Mode IN ('device')
	BEGIN

		/*
		Code - код устройства
		Brand  - Brand (Производитель
		Name - Это составное поле из Name(устройства) + ROm(размер Rom) + Color + Code (код устройства)
		*/

		SELECT 
            GuidID = V.Code,
			--
            V.isActive,
            Category = V.Category_Name,
            Code = ISNULL(V.ModelCode, v.Code),
            Brand = V.Brand_Name,
			-- Это составное поле из Name(устройства) + ROm(размер Rom) + Color + Code (код устройства) (еще раз ?)
			Name = concat(V.Name, ' / ' + V.RamSize_Name, ' / ' + V.RomSize_Name, ' / ' + V.Color) 
		FROM [C2-LIS-AG01\MDS].MDS.mdm.Device_Smart_uat AS V -- ! контур uat = DEV
		WHERE 1=1
			AND isnull(V.isActive, 1) = 1
		order by Brand
	END

	

END

