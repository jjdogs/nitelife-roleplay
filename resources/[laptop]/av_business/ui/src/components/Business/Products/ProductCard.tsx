import {
  Card,
  Group,
  Text,
  Image,
  Stack,
  Button,
  Badge,
  Box,
  Tooltip,
} from "@mantine/core";
import { IngredientsType, JobItem } from "../../../types/types";

interface Properties {
  lang: any;
  product: JobItem;
  inventory: string;
  handleEdit: (product: JobItem) => void;
  handleDelete: (name: string) => void;
  ingredients: IngredientsType[];
}

export const ProductCard = ({
  ingredients,
  lang,
  product,
  inventory,
  handleDelete,
  handleEdit,
}: Properties) => {
  const getIngredientLabel = (input: string): string => {
    const ingredient = ingredients.find((ing) => ing.value === input);
    return ingredient ? ingredient.label : input;
  };
  return (
    <Card
      padding="lg"
      radius="sm"
      h={320}
      style={{
        backgroundColor: "var(--bg-card)",
        border: "1px solid var(--border)",
        display: "flex",
        flexDirection: "column",
      }}
    >
      <Group justify="space-between" align="flex-start" mb="md">
        <Group gap="sm">
          <Box
            style={{
              width: 44,
              height: 44,
              backgroundColor: "var(--bg-sidebar)",
              borderRadius: 8,
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              border: "1px solid var(--border)",
            }}
          >
            <Image
              src={
                product.image
                  ? product.image
                  : `${`https://cfx-nui-${inventory}${product?.name}.png`}`
              }
              fallbackSrc="./item_default.png"
              w={40}
            />
          </Box>
          <Stack gap={2}>
            <Tooltip label={product.label} color="var(--tooltip)" fz="xs">
              <Text
                fw={600}
                size="lg"
                maw={120}
                truncate
                style={{
                  color: "var(--text-main)",
                  fontFamily: "var(--font-display)",
                  textTransform: "uppercase",
                }}
              >
                {product.label}
              </Text>
            </Tooltip>
            <Text
              size="xs"
              fw={700}
              style={{ color: "var(--cyan)", textTransform: "uppercase" }}
            >
              {product.type}
            </Text>
          </Stack>
        </Group>
        <Text
          fw={700}
          size="xl"
          style={{ color: "var(--success)", fontFamily: "var(--font-display)" }}
        >
          ${product.price}
        </Text>
      </Group>
      <Text size="xs" style={{ color: "var(--text-dim)", lineHeight: 1.5 }}>
        {product.description}
      </Text>
      <Box
        mt="xs"
        flex={1}
        p="xs"
        style={{
          backgroundColor: "var(--bg-input)",
          borderRadius: 6,
          border: "1px solid var(--border)",
        }}
      >
        <Text
          size="10px"
          fw={700}
          mb={8}
          style={{ color: "var(--accent)", textTransform: "uppercase" }}
        >
          {lang.ingredients}
        </Text>
        <Group gap={6}>
          {product.ingredients.slice(0, 6).map((ing, index) => (
            <Badge
              key={index}
              variant="outline"
              size="sm"
              styles={{
                root: {
                  borderColor: "var(--border)",
                  color: "var(--text-main)",
                  textTransform: "none",
                  fontWeight: 400,
                  backgroundColor: "rgba(255,255,255,0.075)",
                },
              }}
            >
              {getIngredientLabel(ing)}
            </Badge>
          ))}
          {product.ingredients.length > 6 && (
            <Text size="xs" fw={700} style={{ color: "var(--accent)" }}>
              +{product.ingredients.length - 6} more
            </Text>
          )}
        </Group>
      </Box>
      <Group justify="flex-end" gap="sm" mt="sm">
        <Button
          size="xs"
          variant="light"
          color="gray"
          onClick={() => handleEdit(product)}
          style={{ color: "var(--text-dim)" }}
        >
          {lang.edit}
        </Button>
        <Button
          size="xs"
          variant="light"
          color="red"
          onDoubleClick={() => {
            handleDelete(product.name);
          }}
        >
          {lang.delete}
        </Button>
      </Group>
    </Card>
  );
};
