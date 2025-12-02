import matplotlib.pyplot as plt

# Данные
x = list(range(1, 11))  # 1–10 млн
y = [8.7, 17.2, 25.5, 33.8, 42.0, 50.1, 58.0, 66.2, 74.3, 82.5]

# Настройки шрифта (для русского языка и совместимости с LaTeX)
plt.rcParams.update({
    "font.family": "serif",
    "font.size": 12,
    "text.usetex": False,  # чтобы не требовался LaTeX в системе
    "axes.linewidth": 0.8,
})

fig, ax = plt.subplots(figsize=(6, 4))

# График
ax.plot(x, y, marker='o', color='black', linewidth=1.2, markersize=4)

# Подписи осей
ax.set_xlabel('Объём данных, млн событий')
ax.set_ylabel('Время обработки, с')

# Сетка
ax.grid(True, linestyle='--', linewidth=0.5, alpha=0.7)

# Ограничения осей
ax.set_xlim(0, 11)
ax.set_ylim(0, 90)

# Сохранение
plt.tight_layout()
plt.savefig('performance.pdf', format='pdf', bbox_inches='tight')
plt.close()

print("✅ График сохранён как performance.pdf")