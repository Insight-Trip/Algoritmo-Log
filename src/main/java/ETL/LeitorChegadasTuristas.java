package ETL;

import java.io.IOException;
import java.io.InputStream;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.List;

import Model.VooExterior;
import org.apache.poi.hssf.usermodel.HSSFWorkbook;
import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class LeitorChegadasTuristas {

    private static final Logger logger = LoggerFactory.getLogger(LeitorChegadasTuristas.class);

    // Definição das colunas
    private static final int COL_NOME_PAIS_ORIGEM = 2;    // C
    private static final int COL_ID_PAIS_ORIGEM = 3;      // D
    private static final int COL_ID_ESTADO_DESTINO = 5;   // F
    private static final int COL_VIA = 7;                 // H
    private static final int COL_ANO = 8;                 // I
    private static final int COL_MES = 10;                // K
    private static final int COL_QTD_VIAGENS = 11;        // L

    public static List<VooExterior> ExtrairVoo(String nomeArquivo, InputStream arquivo) {
        try {
            logger.info("\nIniciando leitura do arquivo {}\n", nomeArquivo);

            Workbook workbook;
            if (nomeArquivo.endsWith(".xlsx")) {
                workbook = new XSSFWorkbook(arquivo);
            } else {
                workbook = new HSSFWorkbook(arquivo);
            }

            Sheet sheet = workbook.getSheetAt(0);

            List<VooExterior> voosExtraidos = new ArrayList<>();

            for (Row row : sheet) {

                if (row.getRowNum() == 0) {

                    int[] colIndices = {COL_NOME_PAIS_ORIGEM, COL_ID_PAIS_ORIGEM, COL_ID_ESTADO_DESTINO, COL_VIA, COL_ANO, COL_MES, COL_QTD_VIAGENS};

                    for (int i = 0; i < colIndices.length; i++) {
                        Cell cell = row.getCell(colIndices[i]);
                        String coluna = (cell != null) ? cell.getStringCellValue() : "N/A";
                        // Se necessário, você pode logar os nomes das colunas aqui
                    }
                    continue;
                }

                logger.info("Lendo linha {}", row.getRowNum());

                try {
                    String nomePaisOrigem = row.getCell(COL_NOME_PAIS_ORIGEM).getStringCellValue();
                    Integer idPaisOrigem = getIntegerCellValue(row.getCell(COL_ID_PAIS_ORIGEM));
                    Integer idEstadoDestino = getIntegerCellValue(row.getCell(COL_ID_ESTADO_DESTINO));
                    Integer via = getIntegerCellValue(row.getCell(COL_VIA));
                    Integer ano = getIntegerCellValue(row.getCell(COL_ANO));
                    Integer mes = getIntegerCellValue(row.getCell(COL_MES));
                    Integer qtdViagens = getIntegerCellValue(row.getCell(COL_QTD_VIAGENS));

                    if (via == 1 && qtdViagens > 0 &&
                            idPaisOrigem != null && !nomePaisOrigem.equals("Outros Países") && !nomePaisOrigem.equals("Países não especificados") &&
                            idEstadoDestino != null && idEstadoDestino != 99 &&
                            ano != null && mes != null) {

                        // Transformando paisOrigem "China, Hong Kong" em "China"
                        if (idPaisOrigem == 41) {
                            nomePaisOrigem = "China";
                            idPaisOrigem = 40;
                        }

                        logger.info("Adicionando viagem à lista: {} - {} - {} - {} - {} - {}",
                                nomePaisOrigem, idPaisOrigem, idEstadoDestino, ano, mes, qtdViagens);
                        VooExterior voo = new VooExterior(idPaisOrigem, idEstadoDestino, ano, mes, qtdViagens);
                        voosExtraidos.add(voo);
                    }
                } catch (NullPointerException | IllegalStateException e) {
                    logger.error("Erro ao processar a linha {}: {}", row.getRowNum(), e.getMessage());
                }
            }

            workbook.close();

            logger.info("\nLeitura do arquivo finalizada\n");

            return voosExtraidos;
        } catch (IOException e) {
            logger.error("Erro ao ler o arquivo {}: {}", nomeArquivo, e.getMessage(), e);
            throw new RuntimeException(e);
        }
    }

    private static Integer getIntegerCellValue(Cell cell) {
        if (cell == null) {
            return null;
        }

        switch (cell.getCellType()) {
            case NUMERIC:
                return (int) cell.getNumericCellValue();
            case STRING:
                try {
                    return Integer.parseInt(cell.getStringCellValue());
                } catch (NumberFormatException e) {
                    return null;
                }
            default:
                return null;
        }
    }

    private LocalDate converterDate(java.util.Date data) {
        return data.toInstant().atZone(ZoneId.systemDefault()).toLocalDate();
    }
}